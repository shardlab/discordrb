# frozen_string_literal: true

require 'discordrb/voice/encoder'
require 'discordrb/voice/network'
require 'discordrb/voice/timer'
require 'discordrb/logger'
require 'ffi'

# Voice support
module Discordrb::Voice
  # How long one voice packet should ideally be (20ms as defined by Discord)
  IDEAL_LENGTH = 20.0

  # How many bytes of data to read (1920 bytes * 2 channels) from audio PCM data
  DATA_LENGTH = 1920 * 2

  # This class represents a connection to a Discord voice server and channel. It can be used to play audio files and
  # streams and to control playback on currently playing tracks. The method {Bot#voice_connect} can be used to connect
  # to a voice channel.
  #
  # discordrb does latency adjustments every now and then to improve playback quality. I made sure to put useful
  # defaults for the adjustment parameters, but if the sound is patchy or too fast (or the speed varies a lot) you
  # should check the parameters and adjust them to your connection: {VoiceBot#adjust_interval},
  # {VoiceBot#adjust_offset}, and {VoiceBot#adjust_average}.
  class VoiceBot
    # @return [Channel] the current voice channel
    attr_reader :channel

    # @!visibility private
    attr_writer :channel

    # @return [Integer, nil] the amount of time the stream has been playing, or `nil` if nothing has been played yet.
    attr_reader :stream_time

    # @return [Encoder] the encoder used to encode audio files into the format required by Discord.
    attr_reader :encoder

    # @deprecated This attribute is no longer used. The scheduler advances by a fixed {IDEAL_LENGTH} each packet,
    #   so per-packet timing is stable without periodic adjustments.
    # @return [Integer]
    attr_accessor :adjust_interval

    # @deprecated This attribute is no longer used. See {#adjust_interval}.
    # @return [Integer]
    attr_accessor :adjust_offset

    # @deprecated This attribute is no longer used. See {#adjust_interval}.
    # @return [true, false]
    attr_accessor :adjust_average

    # Disable the debug message for packet scheduling.
    # @return [true, false] whether scheduling debug messages should be printed
    attr_accessor :adjust_debug

    # @deprecated This attribute is no longer used. The scheduler always targets {IDEAL_LENGTH} (20ms) per packet.
    # @return [Float]
    attr_accessor :length_override

    # The factor the audio's volume should be multiplied with. `1` is no change in volume, `0` is completely silent,
    # `0.5` is half the default volume and `2` is twice the default.
    # @return [Float] the volume for audio playback, `1.0` by default.
    attr_accessor :volume

    # @!visibility private
    def initialize(channel, bot, token, session, endpoint)
      @bot = bot
      @channel = channel

      @ws = VoiceWS.new(channel, bot, token, session, endpoint)
      @udp = @ws.udp

      @sequence = @time = 0
      @skips = 0

      @adjust_interval = 100
      @adjust_offset = 10
      @adjust_average = false
      @adjust_debug = true

      @volume = 1.0
      @playing = false

      @encoder = Encoder.new
      @ws.connect
    rescue StandardError => e
      Discordrb::LOGGER.log_exception(e)
      raise
    end

    # @return [true, false] whether audio data sent will be encrypted.
    # @deprecated Discord no longer supports unencrypted voice communication.
    def encrypted?
      true
    end

    # Set the filter volume. This volume is applied as a filter for decoded audio data. It has the advantage that using
    # it is much faster than regular volume, but it can only be changed before starting to play something.
    # @param value [Integer] The value to set the volume to. For possible values, see {#volume}
    def filter_volume=(value)
      @encoder.filter_volume = value
    end

    # @see #filter_volume=
    # @return [Integer] the volume used as a filter for ffmpeg/avconv.
    def filter_volume
      @encoder.filter_volume
    end

    # Pause playback. This is not instant; it may take up to 20 ms for this change to take effect. (This is usually
    # negligible.)
    def pause
      @paused = true
    end

    # @see #play
    # @return [true, false] Whether it is playing sound or not.
    def playing?
      @playing
    end

    alias_method :isplaying?, :playing?

    # Continue playback. This change may take up to 100ms to take effect, which is usually negligible.
    def continue
      @paused = false
    end

    # Skips to a later time in the song. It's impossible to go back without replaying the song.
    # @param secs [Float] How many seconds to skip forwards. Skipping will always be done in discrete intervals of
    #   0.05 seconds, so if the given amount is smaller than that, it will be rounded up.
    def skip(secs)
      @skips += (secs * (1000 / IDEAL_LENGTH)).ceil
    end

    # Sets whether or not the bot is speaking (green circle around user).
    # @param value [true, false, Integer] whether or not the bot should be speaking, or a bitmask denoting the audio type
    # @note https://discord.com/developers/docs/topics/voice-connections#speaking for information on the speaking bitmask
    def speaking=(value)
      @playing = value
      @ws.send_speaking(value)
    end

    # Stops the current playback entirely.
    # @param wait_for_confirmation [true, false] Whether the method should wait for confirmation from the playback
    #   method that the playback has actually stopped.
    def stop_playing(wait_for_confirmation = false)
      @was_playing_before = @playing
      @speaking = false
      @playing = false
      sleep IDEAL_LENGTH / 1000.0 if @was_playing_before

      return unless wait_for_confirmation

      @has_stopped_playing = false
      sleep IDEAL_LENGTH / 1000.0 until @has_stopped_playing
      @has_stopped_playing = false
    end

    # Permanently disconnects from the voice channel; to reconnect you will have to call {Bot#voice_connect} again.
    def destroy
      stop_playing
      @bot.voice_destroy(@channel.server.id, false)
      @ws.destroy
    end

    # Plays a stream of raw data to the channel. All playback methods are blocking, i.e. they wait for the playback to
    # finish before exiting the method. This doesn't cause a problem if you just use discordrb events/commands to
    # play stuff, as these are fully threaded, but if you don't want this behaviour anyway, be sure to call these
    # methods in separate threads.
    # @param encoded_io [IO] A stream of raw PCM data (s16le)
    def play(encoded_io)
      stop_playing(true) if @playing
      @retry_attempts = 3
      @first_packet = true

      play_internal do
        buf = nil

        # Read some data from the buffer
        begin
          buf = encoded_io.readpartial(DATA_LENGTH) if encoded_io
        rescue EOFError
          raise IOError, 'File or stream not found!' if @first_packet

          @bot.debug('EOF while reading, breaking immediately')
          next :stop
        end

        # Check whether the buffer has enough data
        if !buf || buf.length != DATA_LENGTH
          @bot.debug("No data is available! Retrying #{@retry_attempts} more times")
          next :stop if @retry_attempts.zero?

          @retry_attempts -= 1
          next
        end

        # Adjust volume
        buf = @encoder.adjust_volume(buf, @volume) if @volume != 1.0 # rubocop:disable Lint/FloatComparison

        @first_packet = false

        # Encode data
        @encoder.encode(buf)
      end

      # If the stream is a process, kill it
      if encoded_io&.pid
        Discordrb::LOGGER.debug("Killing ffmpeg process with pid #{encoded_io.pid.inspect}")

        begin
          pid = encoded_io.pid
          # Windows does not support TERM as a kill signal, so we use KILL. `Process.waitpid` verifies that our
          # child process has not already completed.
          Process.kill(Gem.win_platform? ? 'KILL' : 'TERM', pid) if Process.waitpid(pid, Process::WNOHANG).nil?
        rescue StandardError => e
          Discordrb::LOGGER.warn('Failed to kill ffmpeg process! You *might* have a process leak now.')
          Discordrb::LOGGER.warn("Reason: #{e}")
        end
      end

      # Close the stream
      encoded_io.close
    end

    # Plays an encoded audio file of arbitrary format to the channel.
    # @see Encoder#encode_file
    # @see #play
    def play_file(file, options = '')
      play @encoder.encode_file(file, options)
    end

    # Plays a stream of encoded audio data of arbitrary format to the channel.
    # @see Encoder#encode_io
    # @see #play
    def play_io(io, options = '')
      play @encoder.encode_io(io, options)
    end

    # Plays a stream of audio data in the DCA format. This format has the advantage that no recoding has to be
    # done - the file contains the data exactly as Discord needs it.
    # @note DCA playback will not be affected by the volume modifier ({#volume}) because the modifier operates on raw
    #   PCM, not opus data. Modifying the volume of DCA data would involve decoding it, multiplying the samples and
    #   re-encoding it, which defeats its entire purpose (no recoding).
    # @see https://github.com/bwmarrin/dca
    # @see #play
    def play_dca(file)
      stop_playing(true) if @playing

      @bot.debug "Reading DCA file #{file}"
      input_stream = File.open(file)

      magic = input_stream.read(4)
      raise ArgumentError, 'Not a DCA1 file! The file might have been corrupted, please recreate it.' unless magic == 'DCA1'

      # Read the metadata header, then read the metadata and discard it as we don't care about it
      metadata_header = input_stream.read(4).unpack1('l<')
      input_stream.read(metadata_header)

      # Play the data, without re-encoding it to opus
      play_internal do
        begin
          # Read header
          header_str = input_stream.read(2)

          unless header_str
            @bot.debug 'Finished DCA parsing (header is nil)'
            next :stop
          end

          header = header_str.unpack1('s<')

          raise 'Negative header in DCA file! Your file is likely corrupted.' if header.negative?
        rescue EOFError
          @bot.debug 'Finished DCA parsing (EOFError)'
          next :stop
        end

        # Read bytes
        input_stream.read(header)
      end
    end

    alias_method :play_stream, :play_io

    private

    # Plays the data from the IO stream as Discord requires it
    def play_internal
      count = 0
      @playing = true
      self.speaking = true

      # Track the *scheduled* send time for the next packet. Advancing this by exactly IDEAL_LENGTH
      # each iteration (rather than re-sampling the clock after send_audio) ensures that any jitter
      # from encryption, UDP, or GC does not accumulate into the inter-packet interval. Discord's
      # jitter buffer expects RTP timestamps every 20ms; drifting even a fraction of a ms per packet
      # eventually drains the buffer and causes audible hiccups.
      next_packet_at = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) + IDEAL_LENGTH

      loop do
        # If paused, wait and then rebase the schedule so we don't burst packets on resume.
        if @paused
          sleep 0.1 while @paused
          next_packet_at = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond) + IDEAL_LENGTH
        end

        break unless @playing

        # Get timestamp before encoding
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)

        # If we should skip, get some data, discard it and go to the next iteration
        if @skips.positive?
          @skips -= 1
          yield
          next
        end

        # Track packet count, sequence and time (Discord requires this)
        count += 1
        increment_packet_headers

        # Get packet data
        buf = yield

        # Stop doing anything if the stop signal was sent
        break if buf == :stop

        # Proceed to the next packet if we got nil
        next unless buf

        # Track intermediate time so we can report how much encoding contributed to the frame budget
        intermediate_adjust = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)

        now = Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
        sleep_duration = (next_packet_at - now) / 1000.0
        if sleep_duration.positive?
          @bot.debug("Waiting for next frame: #{sleep_duration * 1000}ms (encoding #{intermediate_adjust - start_time}ms)") if @adjust_debug
          sleep sleep_duration
        end

        # Send the packet
        @udp.send_audio(buf, @sequence, @time)

        # Set the stream time (for tracking how long we've been playing)
        @stream_time = count * IDEAL_LENGTH / 1000

        # Advance the schedule by exactly one packet period, regardless of actual send time.
        next_packet_at += IDEAL_LENGTH
      end

      @bot.debug('Sending five silent frames to clear out buffers')

      5.times do
        increment_packet_headers
        @udp.send_audio(Encoder::OPUS_SILENCE, @sequence, @time)

        # Length adjustments don't matter here, we can just wait 20ms since nobody is going to hear it anyway
        sleep IDEAL_LENGTH / 1000.0
      end

      @bot.debug('Performing final cleanup after stream ended')

      # Final clean-up
      stop_playing

      # Notify any stop_playing methods running right now that we have actually stopped
      @has_stopped_playing = true
    end

    # Increment sequence and time
    def increment_packet_headers
      @sequence + 10 < 65_535 ? @sequence += 1 : @sequence = 0
      @time + 9600 < 4_294_967_295 ? @time += 960 : @time = 0
    end
  end
end
