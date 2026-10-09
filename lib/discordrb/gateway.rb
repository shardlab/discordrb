# frozen_string_literal: true

module Discordrb
  # Implementation of the Discord gateway.
  class Gateway
    # Mapping of opcodes.
    OPCODES = {
      dispatch: 0,
      heartbeat: 1,
      identify: 2,
      presence_update: 3,
      voice_state_update: 4,
      resume: 6,
      reconnect: 7,
      request_server_members: 8,
      invalid_session: 9,
      hello: 10,
      heartbeat_ack: 11,
      request_soundboard_sounds: 31,
      request_channel_info: 43
    }.freeze

    # Properties sent when identifying.
    PROPERTIES = {
      os: RUBY_PLATFORM,
      device: 'discordrb',
      browser: 'discordrb'
    }.freeze

    # @!visibility private
    Session = Struct.new(:id, :resume_url, :sequence)

    # The version of the gateway to use for connections.
    VERSION = 9

    # Member count before a server is considered to be large.
    LARGE_THRESHOLD = 250

    # The URL that's used to initially connect to the gateway.
    BASE_URL = 'wss://gateway.discord.gg'

    # @return [Integer] the intents of the gateway connection.
    attr_reader :intents

    # @!visibility private
    def initialize(bot, shard, compression, intents)
      @bot = bot
      @shard = shard
      @intents = intents
      @grow_reconnect = true
      @reconnect_seconds = 4
      @check_heartbeats = true
      @should_reconnect = Queue.new
      @compression = (compression || :large)
    end

    # Block execution until the gateway permanently closes.
    # @return [nil]
    def sync
      @connect_loop.join
      nil
    end

    # Disconnect the bot from the gateway, instantly going offline.
    # @return [nil]
    def stop
      @done = true
      @websocket&.close(code: 1000)
      @websocket&.thread&.join
      nil
    end

    # Connect to the gateway. This returns when the bot has successfully
    #   connected or when the connection could not be established.
    # @return [nil]
    def run_async
      @connect_loop = Thread.new do
        Thread.current[:discordrb_name] = 'gateway loop'
        connect
      end

      sleep(0.01) until @failed || @session
      nil
    end

    # Check if the gateway connection is currently open.
    # @return [true, false] Whether or not the gateway connection is open.
    def open?
      @websocket&.connected? || false
    end

    # Heartbeat ACKs are Discord's client-side check on whether the connection is still
    #   alive. If set to `true` (default), the gateway  will use that functionality to
    #   detect zombie connections and reconnect. However, it may lead to instability if
    #   there's some problem with the ACKs. If this occurs this value can be set to `false`.
    # @param check [true, false] whether or not the gateway should check for heartbeat ACKs.
    # @return [true, false] Whether or not the gateway will check for heartbeat ACKs.
    def check_for_heartbeat_acks=(check)
      @check_heartbeats = check
    end

    # Send the presence update event to the gateway.
    # @return [true, false, nil] Whether or not the event was successfully sent.
    def modify_presence(
      afk:, since:, status:, activities: [], **rest
    )
      options = {
        afk: afk,
        since: since,
        status: status.to_s,
        activities: activities&.to_a,
        **rest
      }

      send_command(OPCODES[:presence_update], options)
    end

    # Send the update voice state event to the gateway.
    # @return [true, false, nil] Whether or not the event was successfully sent.
    def modify_voice_state(
      server:, channel:, mute: false, deaf: false, **rest
    )
      options = {
        self_mute: mute,
        self_deaf: deaf,
        guild_id: server.resolve_id,
        channel_id: channel&.resolve_id,
        **rest
      }

      send_command(OPCODES[:voice_state_update], options)
    end

    # Send the request channel info event to the gateway.
    # @return [true, false, nil] Whether or not the event was successfully sent.
    def request_channel_info(server:, fields:)
      options = {
        guild_id: server.resolve_id,
        fields: [*fields].map(&:to_s)
      }

      send_command(OPCODES[:request_channel_info], options)
    end

    # Send the request guild members event to the gateway.
    # @return [true, false, nil] Whether or not the event was successfully sent.
    def request_server_members(
      server:, query: nil, limit: nil, presences: nil,
      users: nil, nonce: nil, **rest
    )
      options = {
        nonce: nonce,
        query: query,
        limit: limit,
        presences: presences,
        guild_id: server.resolve_id,
        user_ids: users ? [*users].map(&:resolve_id) : users,
        **rest
      }.compact

      send_command(OPCODES[:request_server_members], options)
    end

    # Send the request soundboard sounds event to the gateway.
    # @return [true, false, nil] Whether or not the event was successfully sent.
    def request_soundboard_sounds(servers:)
      options = { guild_ids: [*servers].map(&:resolve_id) }

      send_command(OPCODES[:request_soundboard_sounds], options)
    end

    # Send a payload to Discord.
    # @param opcode [Integer] The opcode to send.
    # @param inner_payload [Object] The data of the payload.
    # @return [true, false, nil] Whether or not the event was successfully sent.
    def send_command(opcode, inner_payload)
      @websocket&.send({ op: opcode, d: inner_payload }.to_json)
    end

    # @!visibility private
    def url
      unless @query_params
        params = {
          v: VERSION,
          encoding: :json,
          compress: ('zlib-stream' if @compression == :stream)
        }

        @query_params = URI.encode_www_form(params.compact)
      end

      "#{(@session&.resume_url || BASE_URL)}?#{@query_params}"
    end

    # @!visibility private
    def notify_message(message)
      message = JSON.parse(message)
      sequence = message['s']
      (@session&.sequence = sequence) if sequence
      LOGGER.in(message)

      case message['op']
      when OPCODES[:dispatch]
        handle_dispatch_message(message)
      when OPCODES[:heartbeat]
        send_command(OPCODES[:heartbeat], message['s'])
      when OPCODES[:reconnect]
        @websocket&.close(code: 4500)
      when OPCODES[:invalid_session]
        @session = nil unless message['d'] == true
        @websocket&.close(code: 4500)
      when OPCODES[:hello]
        initialize_heartbeats(message['d'])
        send_command(OPCODES[:heartbeat], 0)
        @session ? send_resume : send_identify
      when OPCODES[:heartbeat_ack]
        @heartbeat_acknowledged = true
      end
    end

    # @!visibility private
    def notify_close(code:, reason:)
      reconnect = true

      @heartbeat_manager&.kill

      @bot.__send__(:raise_event, Events::DisconnectEvent.new(@bot))

      unless @done
        case code
        when 4014 # This close code is un-recoverable. It's a seperate branch so we can log a better error.
          reconnect = false
          LOGGER.error(<<~ERROR)
            You attempted to identify with privileged intents that your bot is not authorized to use.
            Please enable the privileged intents on the bot page of your application on the discord developer page.
            You can read more here https://discord.com/developers/docs/topics/gateway#privileged-intents
          ERROR

        when 4004, 4010, 4011, 4012, 4013 # All of these are un-recoverable as well. Do not attempt to reconnect.
          reconnect = false
          LOGGER.error("The gateway connection has permanently closed (code: #{code}, reason: \"#{reason}\").")

        when 1000, 1001, 1006, 1012 # All of these are caused by the underlying server going away. May or may-not be recoverable.
          sleep((rand(5..8) * 1.5))
          LOGGER.debug("Received a close code saying that the gateway is going away (code: #{code}, reason: \"#{reason}\").")

        when 4000, 4001, 4002, 4005 # Most of these are caused by sending an invalid payload. We can usually reconnect.
          LOGGER.warn("The gateway connection has closed due to an error (code: #{code}, reason: \"#{reason}\").")

        when 4007, 4003, 4009 # Our session has been invalidated. We can always attempt to reconnect, but the attempt may fail.
          @session = nil
          LOGGER.debug("Received a close code saying that our session is now invalid (code: #{code}, reason: \"#{reason}\").")

        when 4500 # This is our internal close code that we use to signal an immediate reconnect. We can always attempt reconnect.
          LOGGER.debug("Received an internal close code (code: #{code}, reason: \"#{reason}\"). Waiting 0 seconds before reconnecting.")

        else # We disconnected in a way that wasn't expected. We can reconnect, but we must wait before reconnecting in this case.
          seconds = reconnect_seconds
          LOGGER.warn("The gateway connection has unexpectedly closed (code: #{code}, reason: \"#{reason}\"). Waiting #{seconds} seconds before reconnecting.")
          sleep(seconds)
        end
      end

      reconnect = false if @done
      @should_reconnect << reconnect
      @failed = true unless reconnect
    end

    private

    # @!visibility private
    def connect
      loop do
        @websocket = WebSocket.new(self, @compression, true)
        @websocket.connect.join
        break unless @should_reconnect.shift
      rescue StandardError => e
        @heartbeat_manager&.kill
        @bot.log_exception(e)
      end
    end

    # @!visibility private
    def send_resume
      options = {
        token: @bot.token,
        seq: @session.sequence,
        session_id: @session.id
      }

      send_command(OPCODES[:resume], options)
    end

    # @!visibility private
    def send_identify
      options = {
        shard: @shard,
        token: @bot.token,
        intents: @intents,
        properties: PROPERTIES,
        large_threshold: LARGE_THRESHOLD,
        compress: @compression == :large
      }.compact

      send_command(OPCODES[:identify], options)
    end

    # @!visibility private
    def initialize_heartbeats(data)
      # Kill the old heartbeat thread if one exists.
      @heartbeat_manager&.kill

      # Reset ACK handling, so we don't keep reconnecting.
      @heartbeat_acknowledged = true

      # The interval is in MS so we need to convert to seconds.
      @heartbeat_interval = (data['heartbeat_interval'].to_f / 1000.0)

      @heartbeat_manager = Thread.new do
        Thread.current[:discordrb_name] = 'heartbeat manager'

        loop do
          sleep(@heartbeat_interval)

          if @check_heartbeats && !@heartbeat_acknowledged
            LOGGER.warn('The last heartbeat was not acknowledged. This is a zombie connection.')
            @websocket&.close(code: 4500)
            break
          else
            @heartbeat_acknowledged = false if @check_heartbeats

            send_command(OPCODES[:heartbeat], @session&.sequence || 0)

            # Make sure we do this AFTER we've sent the actual packet.
            @bot.raise_heartbeat_event
          end
        end
      end
    end

    # @!visibility private
    def handle_dispatch_message(message)
      data = message['d']
      type = message['t'].to_sym

      if type == :READY
        LOGGER.info("Discord using gateway protocol version: #{data['v']}, requested: #{VERSION}")
        @session = Session.new(data['session_id'], data['resume_gateway_url'], 0)
      end

      @bot.dispatch(type, data)
    end

    # @!visibility private
    def reconnect_seconds
      if @grow_reconnect
        @reconnect_seconds = [@reconnect_seconds * 2, 77].min
        @grow_reconnect = false if @reconnect_seconds >= 77
      else
        @reconnect_seconds = [@reconnect_seconds / 2, 5].max
        @grow_reconnect = true if @reconnect_seconds <= 5
      end

      @reconnect_seconds * rand(0.8..1.5)
    end
  end
end
