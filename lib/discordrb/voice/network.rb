# frozen_string_literal: true

require 'websocket-client-simple'
require 'socket'
require 'json'

require 'discordrb/websocket'
require 'discordrb/voice/opcodes'

begin
  LIBSODIUM_AVAILABLE = if ENV['DISCORDRB_NONACL']
                          false
                        else
                          require 'discordrb/voice/sodium'
                        end
rescue LoadError
  puts "libsodium not available! You can continue to use discordrb as normal but voice support won't work.
        Read https://github.com/shardlab/discordrb/wiki/Installing-libsodium for more details."
  LIBSODIUM_AVAILABLE = false
end

begin
  LIBDAVE_AVAILABLE = require 'discordrb/voice/dave'
rescue LoadError, FFI::NotFoundError
  LIBDAVE_AVAILABLE = false
end

module Discordrb::Voice
  # Signifies to Discord that encryption should be used
  # @deprecated Discord now supports multiple encryption options.
  # TODO: Resolve replacement for this constant.
  ENCRYPTED_MODE = 'aead_xchacha20_poly1305_rtpsize'

  # Signifies to Discord that no encryption should be used
  # @deprecated Discord no longer supports unencrypted voice communication.
  PLAIN_MODE = 'plain'

  # Encryption modes supported by Discord
  ENCRYPTION_MODES = %w[aead_xchacha20_poly1305_rtpsize].freeze

  # Represents a UDP connection to a voice server. This connection is used to send the actual audio data.
  class VoiceUDP
    # @return [true, false] whether or not UDP communications are encrypted.
    # @deprecated Discord no longer supports unencrypted voice communication.
    attr_accessor :encrypted
    alias_method :encrypted?, :encrypted

    # Sets the secret key used for encryption
    attr_writer :secret_key

    # The UDP encryption mode
    attr_reader :mode

    # @!visibility private
    attr_writer :mode

    # Creates a new UDP connection. Only creates a socket as the discovery reply may come before the data is
    # initialized.
    def initialize
      @socket = UDPSocket.new
      @encrypted = true
    end

    # Initializes the UDP socket with data obtained from opcode 2.
    # @param ip [String] The IP address to connect to.
    # @param port [Integer] The port to connect to.
    # @param ssrc [Integer] The Super Secret Relay Code (SSRC). Discord uses this to identify different voice users
    #   on the same endpoint.
    def connect(ip, port, ssrc)
      @ip = ip
      @port = port
      @ssrc = ssrc

      @dave_encryptor&.assign_audio_ssrc(@ssrc)
    end

    # Waits for a UDP discovery reply, and returns the sent data.
    # @return [Array(String, Integer)] the IP and port received from the discovery reply.
    def receive_discovery_reply
      # Wait for a UDP message
      message = @socket.recv(74)
      ip = message[8..-3].delete("\0")
      port = message[-2..].unpack1('n')
      [ip, port]
    end

    # Makes an audio packet from a buffer and sends it to Discord.
    # @param buf [String] The audio data to send, must be exactly one Opus frame
    # @param sequence [Integer] The packet sequence number, incremented by one for subsequent packets
    # @param time [Integer] When this packet should be played back, in no particular unit (essentially just the
    #   sequence number multiplied by 960)
    def send_audio(buf, sequence, time)
      # Header of the audio packet
      header = generate_header(sequence, time)

      buf = encrypt_frame(buf)

      nonce = generate_nonce
      buf = encrypt_audio(buf, header, nonce)
      data = header + buf + nonce.byteslice(0, 4)

      send_packet(data)
    end

    # Sends the UDP discovery packet with the internally stored SSRC. Discord will send a reply afterwards which can
    # be received using {#receive_discovery_reply}
    def send_discovery
      # Create empty packet
      discovery_packet = ''

      # Add Type request (0x1 = request, 0x2 = response)
      discovery_packet += [0x1].pack('n')

      # Add Length (excluding Type and itself = 70)
      discovery_packet += [70].pack('n')

      # Add SSRC
      discovery_packet += [@ssrc].pack('N')

      # Add 66 zeroes so the packet is 74 bytes long
      discovery_packet += "\0" * 66

      send_packet(discovery_packet)
    end

    private

    def activate_dave!(session, user_id)
      @dave_encryptor ||= Discordrb::Voice::DAVE::Encryptor.new
      @dave_encryptor.assign_audio_ssrc(@ssrc) if @ssrc
      @dave_encryptor.passthrough_mode = false

      @dave_key_ratchet = session.key_ratchet(user_id)
      @dave_encryptor.key_ratchet = @dave_key_ratchet
      @dave_active = true
    end

    def deactivate_dave!
      @dave_encryptor&.passthrough_mode = true
      @dave_active = false
      @dave_key_ratchet = nil
    end

    def dave_active?
      @dave_active
    end

    def encrypt_frame(buf)
      return buf unless dave_active?

      @dave_encryptor.encrypt_audio_frame(@ssrc, buf)
    end

    # Encrypts audio data using libsodium
    # @param buf [String] The encoded audio data to be encrypted
    # @param header [String] The RTP header of the packet, used as associated data
    # @param nonce [String] The nonce to be used to encrypt the data
    # @return [String] the audio data, encrypted
    def encrypt_audio(buf, header, nonce)
      raise 'No secret key found, despite encryption being enabled!' unless @secret_key

      case @mode
      when 'aead_xchacha20_poly1305_rtpsize'
        Discordrb::Voice::XChaCha20AEAD.encrypt(buf, header, nonce, @secret_key)
      else
        raise "`#{@mode}' is not a supported encryption mode"
      end
    end

    def send_packet(packet)
      @socket.send(packet, 0, @ip, @port)
    end

    # @return [String]
    def generate_nonce
      case @mode
      when 'aead_xchacha20_poly1305_rtpsize'
        case @incremental_nonce
        when nil, 0xff_ff_ff_ff
          @incremental_nonce = 0
        else
          @incremental_nonce += 1
        end
        [@incremental_nonce].pack('N').ljust(24, "\0")
      else
        raise "`#{@mode}' is not a supported encryption mode"
      end
    end

    # @return [String]
    def generate_header(sequence, time)
      [0x80, 0x78, sequence, time, @ssrc].pack('CCnNN')
    end
  end

  # Represents a websocket client connection to the voice server. The websocket connection (sometimes called vWS) is
  # used to manage general data about the connection, such as sending the speaking packet, which determines the green
  # circle around users on Discord, and obtaining UDP connection info.
  class VoiceWS
    # The version of the voice gateway that's supposed to be used.
    VOICE_GATEWAY_VERSION = 8

    # @return [VoiceUDP] the UDP voice connection over which the actual audio data is sent.
    attr_reader :udp

    # Makes a new voice websocket client, but doesn't connect it (see {#connect} for that)
    # @param channel [Channel] The voice channel to connect to
    # @param bot [Bot] The regular bot to which this vWS is bound
    # @param token [String] The authentication token which is also used for REST requests
    # @param session [String] The voice session ID Discord sends over the regular websocket
    # @param endpoint [String] The endpoint URL to connect to
    def initialize(channel, bot, token, session, endpoint)
      raise 'libsodium is unavailable - unable to create voice bot! Please read https://github.com/shardlab/discordrb/wiki/Installing-libsodium' unless LIBSODIUM_AVAILABLE

      @channel = channel
      @bot = bot
      @token = token
      @session = session

      @endpoint = endpoint

      @udp = VoiceUDP.new
      @media_ready = false
      @dave_expected_user_ids = Set.new([@bot.profile.id.to_s])
      @dave_expected_user_ids.merge(@channel.users.map { |user| user.id.to_s })
    end

    # Send a connection init packet (op 0)
    # @param server_id [Integer] The ID of the server to connect to
    # @param bot_user_id [Integer] The ID of the bot that is connecting
    # @param session_id [String] The voice session ID
    # @param token [String] The Discord authentication token
    def send_init(server_id, bot_user_id, session_id, token)
      data = {
        server_id: server_id,
        user_id: bot_user_id,
        session_id: session_id,
        token: token
      }

      data[:max_dave_protocol_version] = Discordrb::Voice::DAVE.max_supported_protocol_version if LIBDAVE_AVAILABLE

      send_opcode(
        Opcodes::IDENTIFY,
        data
      )
    end

    # Sends the UDP connection packet (op 1)
    # @param ip [String] The IP to bind UDP to
    # @param port [Integer] The port to bind UDP to
    # @param mode [Object] Which mode to use for the voice connection
    def send_udp_connection(ip, port, mode)
      send_opcode(
        Opcodes::SELECT_PROTOCOL,
        {
          protocol: 'udp',
          data: {
            address: ip,
            port: port,
            mode: mode
          }
        }
      )
    end

    # Send a heartbeat (op 3), has to be done every @heartbeat_interval seconds or the connection will terminate
    def send_heartbeat
      millis = Time.now.strftime('%s%L').to_i
      @bot.debug("Sending voice heartbeat at #{millis}")

      send_opcode(
        Opcodes::HEARTBEAT,
        {
          t: millis,
          seq_ack: @seq
        }
      )
    end

    # Send a speaking packet (op 5). This determines the green circle around the avatar in the voice channel
    # @param value [true, false, Integer] Whether or not the bot should be speaking, can also be a bitmask denoting audio type.
    def send_speaking(value)
      @bot.debug("Speaking: #{value}")
      send_opcode(
        Opcodes::SPEAKING,
        {
          speaking: value,
          delay: 0
        }
      )
    end

    def send_opcode(opcode, data)
      @bot.debug("Sending voice opcode #{opcode} with data: #{data}")
      @client.send({
        op: opcode,
        d: data
      }.to_json, :text)
    end

    def send_binary_opcode(opcode, payload = ''.b)
      @bot.debug("Sending voice binary opcode #{opcode} (#{payload.bytesize} bytes)")
      @client.send(opcode.chr + payload, :binary)
    end

    # Event handlers; public for websocket-simple to work correctly
    # @!visibility private
    def websocket_open
      # Give the current thread a name ('Voice Web Socket Internal')
      Thread.current[:discordrb_name] = 'vws-i'

      # Send the init packet
      send_init(@channel.server.id, @bot.profile.id, @session, @token)
    end

    # @!visibility private
    def websocket_message(msg)
      if msg.type == :binary
        websocket_binary_message(msg.data)
      else
        websocket_text_message(msg.data)
      end
    rescue StandardError => e
      @connection_error ||= e.class
      raise
    end

    def websocket_text_message(msg)
      @bot.debug("Received VWS message! #{msg}")
      packet = JSON.parse(msg)
      @seq = packet['seq'] if packet['seq']

      case packet['op']
      when Discordrb::Voice::Opcodes::READY
        # Opcode 2 contains data to initialize the UDP connection
        @ws_data = packet['d']

        @ssrc = @ws_data['ssrc']
        @port = @ws_data['port']

        @udp_mode = (ENCRYPTION_MODES & @ws_data['modes']).first

        @udp.connect(@ws_data['ip'], @port, @ssrc)
        @udp.send_discovery
      when Discordrb::Voice::Opcodes::SESSION_DESCRIPTION
        # Opcode 4 sends the secret key used for encryption
        @ws_data = packet['d']

        # Reset the sequence when starting a new session
        @seq = 0

        @udp.secret_key = @ws_data['secret_key'].pack('C*')
        @udp.mode = @ws_data['mode']
        setup_dave(@ws_data['dave_protocol_version'].to_i)
        @ready = true
        @media_ready = !dave_required?
      when Discordrb::Voice::Opcodes::HELLO
        # Opcode 8 contains the heartbeat interval.
        @heartbeat_interval = packet['d']['heartbeat_interval']
        send_heartbeat
      when Discordrb::Voice::Opcodes::CLIENT_CONNECT
        update_expected_users(packet.dig('d', 'user_ids'))
      when Discordrb::Voice::Opcodes::CLIENT_DISCONNECT
        remove_expected_user(packet.dig('d', 'user_id'))
      when Discordrb::Voice::Opcodes::DAVE_PREPARE_TRANSITION
        handle_dave_prepare_transition(packet['d'])
      when Discordrb::Voice::Opcodes::DAVE_EXECUTE_TRANSITION
        handle_dave_execute_transition(packet['d']['transition_id'])
      when Discordrb::Voice::Opcodes::DAVE_PREPARE_EPOCH
        handle_dave_prepare_epoch(packet['d'])
      end
    end

    def websocket_binary_message(msg)
      opcode = msg.getbyte(2)
      payload = msg.byteslice(3..) || ''.b
      @bot.debug("Received VWS binary opcode #{opcode} (#{payload.bytesize} bytes)")

      case opcode
      when Discordrb::Voice::Opcodes::DAVE_MLS_EXTERNAL_SENDER
        dave_control_session.external_sender = payload
      when Discordrb::Voice::Opcodes::DAVE_MLS_PROPOSALS
        process_dave_proposals(payload)
      when Discordrb::Voice::Opcodes::DAVE_MLS_COMMIT_WELCOME
        @bot.warn('Ignoring unexpected DAVE commit/welcome echo from voice gateway')
      when Discordrb::Voice::Opcodes::DAVE_MLS_ANNOUNCE_COMMIT_TRANSITION
        transition_id, commit = unpack_transition_payload(payload)
        process_dave_commit(transition_id, commit)
      when Discordrb::Voice::Opcodes::DAVE_MLS_WELCOME
        transition_id, welcome = unpack_transition_payload(payload)
        process_dave_welcome(transition_id, welcome)
      end
    end

    # Communication goes like this:
    # me                    discord
    #   |                      |
    # websocket connect ->     |
    #   |                      |
    #   |     <- websocket opcode 2
    #   |                      |
    # UDP discovery ->         |
    #   |                      |
    #   |       <- UDP reply packet
    #   |                      |
    # websocket opcode 1 ->    |
    #   |                      |
    # ...
    def connect
      # Connect websocket
      @thread = Thread.new do
        Thread.current[:discordrb_name] = 'vws'
        init_ws
      end

      @bot.debug('Started websocket initialization, now waiting for UDP discovery reply')

      # Now wait for opcode 2 and the resulting UDP reply packet
      ip, port = @udp.receive_discovery_reply
      @bot.debug("UDP discovery reply received! #{ip} #{port}")

      # Send UDP init packet with received UDP data
      send_udp_connection(ip, port, @udp_mode)

      @bot.debug('Waiting for op 4 now')

      # Wait for op 4, then finish
      sleep 0.05 until ready_for_media?
    end

    # Disconnects the websocket and kills the thread
    def destroy
      @heartbeat_running = false
    end

    private

    def ready_for_media?
      raise @connection_error if @connection_error

      @ready && @media_ready
    end

    def dave_required?
      @dave_protocol_version&.positive?
    end

    def setup_dave(protocol_version)
      @dave_protocol_version = protocol_version
      return unless dave_required?

      raise 'libdave is unavailable - unable to create DAVE voice session' unless LIBDAVE_AVAILABLE

      @bot.debug("DAVE: Voice gateway requires protocol version #{protocol_version}")
      @pending_dave_session = build_dave_session(protocol_version)
      send_dave_key_package(@pending_dave_session)
    end

    def build_dave_session(protocol_version)
      Discordrb::Voice::DAVE::Session.new(
        protocol_version: protocol_version,
        group_id: @channel.id,
        self_user_id: @bot.profile.id
      ) do |source, reason|
        raise "DAVE MLS failure from #{source}: #{reason}"
      end
    end

    def update_expected_users(user_ids)
      Array(user_ids).each { |user_id| @dave_expected_user_ids << user_id.to_s }
    end

    def remove_expected_user(user_id)
      @dave_expected_user_ids.delete(user_id.to_s)
    end

    def dave_control_session
      @pending_dave_session || @dave_session || raise('DAVE session is not initialized')
    end

    def send_dave_key_package(session)
      @bot.debug('DAVE: Sending MLS key package')
      send_binary_opcode(Opcodes::DAVE_MLS_KEY_PACKAGE, session.key_package)
    end

    def process_dave_proposals(payload)
      @bot.debug("DAVE: Processing MLS proposals (#{payload.bytesize} bytes)")
      commit_welcome = dave_control_session.process_proposals(payload, @dave_expected_user_ids.to_a)
      send_binary_opcode(Opcodes::DAVE_MLS_COMMIT_WELCOME, commit_welcome) if commit_welcome
    end

    def process_dave_commit(transition_id, commit)
      @bot.debug("DAVE: Processing MLS commit for transition #{transition_id}")
      result = dave_control_session.process_commit(commit)

      if result.failed?
        Discordrb::LOGGER.warn("DAVE: Received invalid MLS commit for transition #{transition_id}")
        send_dave_invalid_commit_welcome(transition_id)
        return
      end

      if result.ignored?
        @bot.debug("DAVE: Ignored MLS commit for transition #{transition_id}")
        return
      end

      track_pending_transition(transition_id)
      @bot.debug("DAVE: Transition #{transition_id} is ready")
      send_dave_ready_for_transition(transition_id)
    end

    def process_dave_welcome(transition_id, welcome)
      @bot.debug("DAVE: Processing MLS welcome for transition #{transition_id}")
      dave_control_session.process_welcome(welcome, @dave_expected_user_ids.to_a)
      track_pending_transition(transition_id, activate_pending_session: true)
      @bot.debug("DAVE: Transition #{transition_id} is ready")
      send_dave_ready_for_transition(transition_id)
    end

    def unpack_transition_payload(payload)
      [payload.unpack1('n'), payload.byteslice(2..) || ''.b]
    end

    def handle_dave_prepare_transition(data)
      @pending_transition_id = data['transition_id']
      @pending_transition_protocol_version = data['protocol_version'].to_i
      @activate_pending_session ||= !@pending_dave_session.nil?
      @bot.debug("DAVE: Preparing transition #{@pending_transition_id} for protocol version #{@pending_transition_protocol_version}")

      if @pending_transition_id.zero?
        handle_dave_execute_transition(@pending_transition_id)
      elsif @pending_transition_protocol_version.zero?
        send_dave_ready_for_transition(@pending_transition_id)
      end
    end

    def handle_dave_prepare_epoch(data)
      protocol_version = data['protocol_version'].to_i
      epoch = data['epoch'].to_i
      @bot.debug("DAVE: Preparing epoch #{epoch} for protocol version #{protocol_version}")

      if epoch == 1
        @pending_dave_session = build_dave_session(protocol_version)
        @pending_transition_protocol_version = protocol_version
        send_dave_key_package(@pending_dave_session)
      else
        dave_control_session.protocol_version = protocol_version
        @pending_transition_protocol_version = protocol_version
      end
    end

    def handle_dave_execute_transition(transition_id)
      return unless @pending_transition_id.nil? || transition_id == @pending_transition_id

      if @pending_transition_protocol_version.to_i.zero?
        @udp.send(:deactivate_dave!)
        @dave_protocol_version = 0
        @media_ready = true
        @bot.debug('DAVE: Disabled voice frame encryption')
        clear_pending_transition
        return
      end

      if @activate_pending_session || (@dave_session.nil? && @pending_dave_session)
        @dave_session = @pending_dave_session
        @pending_dave_session = nil
      end

      @udp.send(:activate_dave!, dave_control_session, @bot.profile.id)
      @dave_protocol_version = dave_control_session.protocol_version
      @media_ready = true
      @bot.debug("DAVE: Enabled voice frame encryption with protocol version #{@dave_protocol_version}")
      clear_pending_transition
    end

    def track_pending_transition(transition_id, activate_pending_session: false)
      @pending_transition_id = transition_id
      @pending_transition_protocol_version ||= dave_control_session.protocol_version
      @activate_pending_session = @activate_pending_session || activate_pending_session || !@pending_dave_session.nil?
    end

    def clear_pending_transition
      @pending_transition_id = nil
      @pending_transition_protocol_version = nil
      @activate_pending_session = false
    end

    def send_dave_ready_for_transition(transition_id)
      send_opcode(Opcodes::DAVE_TRANSITION_READY, { transition_id: transition_id })
    end

    def send_dave_invalid_commit_welcome(transition_id)
      send_opcode(Opcodes::DAVE_MLS_INVALID_COMMIT_WELCOME, { transition_id: transition_id })
    end

    def heartbeat_loop
      @heartbeat_running = true
      while @heartbeat_running
        if @heartbeat_interval
          sleep @heartbeat_interval / 1000.0
          send_heartbeat
        else
          # If no interval has been set yet, sleep a second and check again
          sleep 1
        end
      end
    end

    def init_ws
      host = "wss://#{@endpoint}/?v=#{VOICE_GATEWAY_VERSION}"
      @bot.debug("Connecting VWS to host: #{host}")

      # Connect the WS
      @client = Discordrb::WebSocket.new(
        host,
        method(:websocket_open),
        method(:websocket_message),
        proc do |e|
          @connection_error ||= e if !@ready || !@media_ready
          Discordrb::LOGGER.error "VWS error: #{e}"
        end,
        proc do |e|
          @connection_error ||= e if !@ready || !@media_ready
          Discordrb::LOGGER.warn "VWS close: #{e}"
        end
      )

      @bot.debug('VWS connected')

      # Block any further execution
      heartbeat_loop
    end
  end
end
