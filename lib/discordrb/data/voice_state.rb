# frozen_string_literal: true

module Discordrb
  # A voice state represents the state of a member's connection to a voice channel. It includes data like the voice
  # channel the member is connected to and mute/deaf flags.
  class VoiceState
    # @return [Integer] the ID of the user whose voice state is represented by this object.
    attr_reader :user_id

    # @return [true, false] whether this voice state's member is muted server-wide.
    attr_reader :mute

    # @return [true, false] whether this voice state's member is deafened server-wide.
    attr_reader :deaf

    # @return [true, false] whether this voice state's member has muted themselves.
    attr_reader :self_mute

    # @return [true, false] whether this voice state's member has deafened themselves.
    attr_reader :self_deaf

    # @return [true, false] whether this voice state's member is suppressed.
    attr_reader :suppress

    # @return [Timestamp] the time at which a user requested to speak in a stage channel.
    attr_reader :request_to_speak_timestamp

    # @return [Channel] the voice channel this voice state's member is in.
    attr_reader :voice_channel

    # @!visibility private
    def initialize(user_id)
      @user_id = user_id
    end

    # Update this voice state with new data from Discord
    # @note For internal use only.
    # @!visibility private
    def update(channel, mute, deaf, self_mute, self_deaf, suppress, request_to_speak_timestamp)
      @voice_channel = channel
      @mute = mute
      @deaf = deaf
      @self_mute = self_mute
      @self_deaf = self_deaf
      @suppress = suppress
      @request_to_speak_timestamp = request_to_speak_timestamp
    end
  end
end
