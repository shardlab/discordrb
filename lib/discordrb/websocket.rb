# frozen_string_literal: true

module Discordrb
  # @!visibility private
  class WebSocket
    # Zlib boundary used for separating messages split across multiple frames.
    ZLIB_SUFFIX = "\x00\x00\xFF\xFF".b.freeze

    # @return [String] the URL of the connection to use.
    attr_reader :url

    # @return [Thread, nil] the thread used to parse messages from the websocket.
    attr_reader :thread

    # @!visibility private
    def initialize(gateway, compression, should_retry)
      @gateway = gateway
      ssl = OpenSSL::SSL::SSLContext.new
      ssl.set_params(ssl_version: :TLSv1_2) # rubocop:disable Naming/VariableNumber

      @url = @gateway.url
      uri = URI.parse(@url)
      tcp = TCPSocket.new(uri.host, uri.port)
      @ssl = OpenSSL::SSL::SSLSocket.new(tcp, ssl)
      @ssl.sync_close = true

      @websocket = ::WebSocket::Driver.client(self)
      @compression_mode = compression
      @zlib = Zlib::Inflate.new if @compression_mode != :none
    rescue ::SocketError => e
      raise(e) unless should_retry

      time = ((rand(10..13)) * rand(2.67..2.86)).round(2)
      LOGGER.warn("Retrying a SocketError in #{time} seconds")
      sleep(time)
      retry
    end

    # Write a string directly to the underlying TCP socket.
    # @note This method must be implemented to use WebSocket Driver.
    def write(string)
      @ssl.write(string)
    end

    # Check if the WebSocket connection has been successfully established.
    # @return [true, false] Whether or not the connection has been established.
    def connected?
      @websocket.state == :open
    end

    # Close the websocket connection. The close code that is passed matters.
    # @param code [Integer] The close code to close the websocket connection with.
    # @return [true, false] Whether or not the connection was successfully closed.
    def close(code:)
      @websocket.close(nil, code)
    end

    # Send data to the other end of the websocket connection.
    # @param value [String, Array<Integer>] The data that should be sent.
    # @param binary [true, false] Whether the value is a raw binary value.
    # @return [true, false] Whether or not the value was successfully sent.
    def send(value, binary: false)
      LOGGER.out(value) unless binary
      binary ? @websocket.binary(value) : @websocket.text(value)
    end

    # Open the websocket connection. This will asynchronously parse messages.
    # @return [Thread] The thread that is being used to parse websocket messages.
    def connect
      if @gateway.is_a?(Voice::VoiceWS)
        @websocket.on(:open) { @gateway.notify_open }
        @websocket.on(:error) { @gateway.notify_error }
      end

      @websocket.on(:message) { |value| handle_message(value.data) }

      @websocket.on(:close) do |value|
        @gateway.notify_close(code: value.code, reason: value.reason)
      end

      # First, Open the SSL socket and perform the TLS handshake and stuff.
      @ssl.connect

      # After that, we can finally perform the websocket upgrade and handshake.
      @websocket.start

      # Everything before this has worked. From here, delegate to {#start_reading}.
      @thread = Thread.new do
        Thread.current[:discordrb_name] = 'websocket'
        start_reading
      end
    end

    private

    # @!visibility private
    def handle_message(message)
      case @compression_mode
      when :large
        message = Zlib::Inflate.inflate(message) if message.byteslice(0) == 'x'
      when :stream
        @zlib << message
        message.end_with?(ZLIB_SUFFIX) ? (message = @zlib.inflate('')) : return
      end

      @gateway.notify_message(message)
    end

    # @!visibility private
    def start_reading
      @websocket.parse(@ssl.readpartial(4096)) until @websocket.state == :closed
    rescue EOFError
      @gateway.notify_close(code: 4500, reason: 'EOF occurred in the WebSocket thread.')
    rescue SystemCallError => e
      @gateway.notify_close(code: 4500, reason: "#{e.class.name.split('::').last} - #{e.message}.")
    rescue OpenSSL::SSL::SSLError => e
      e.message&.include?('eof') ? @gateway.notify_close(code: 4500, reason: 'Unexpected EOF.') : raise(e)
    ensure
      @ssl&.close unless @ssl&.closed?
    end
  end
end
