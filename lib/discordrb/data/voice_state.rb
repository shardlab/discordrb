# frozen_string_literal: true

module Discordrb
  # A voice state represents the state of a member's connection to a voice channel. It includes data like the voice
  # channel the member is connected to and mute/deaf flags.
  class VoiceState
    # @return [Integer] the ID of the user whose voice state is represented by this object.
    attr_reader :user_id

    # @return [Channel] the voice channel this voice state's member is connected to.
    attr_reader :voice_channel

    # @return [true, false] whether this voice state's member is muted server-wide.
    attr_reader :mute
    alias_method :mute?, :mute

    # @return [true, false] whether this voice state's member is deafened server-wide.
    attr_reader :deaf
    alias_method :deaf?, :deaf

    # @return [true, false] whether this voice state's member has muted themselves.
    attr_reader :self_mute
    alias_method :self_mute?, :self_mute

    # @return [true, false] whether this voice state's member has deafened themselves.
    attr_reader :self_deaf
    alias_method :self_deaf?, :self_deaf

    # @return [true, false] whether this voice state's member is currently streaming via go-live.
    attr_reader :self_stream
    alias_method :self_stream?, :self_stream

    # @return [true, false] whether this voice state's member currently has their cameria enabled.
    attr_reader :self_video
    alias_method :self_video?, :self_video

    # @return [true, false] whether this voice state's member has been suppressed in the stage channel.
    attr_reader :suppress
    alias_method :suppress?, :suppress

    # @return [Time, nil] the time at when this voice state's member requested to speak in the stage channel.
    attr_reader :requested_to_speak_at

    # @!visibility private
    def initialize(data, channel)
      update_data(data, channel)
      @user_id = data['user_id'].to_i
    end

    # @!visibility private
    def update_data(new_data, channel)
      @voice_channel = channel
      @mute = new_data['mute']
      @deaf = new_data['deaf']
      @self_mute = new_data['self_mute']
      @self_deaf = new_data['self_deaf']
      @self_video = new_data['self_video']
      @self_stream = new_data['self_stream'] || false
      @suppress = new_data['suppress']
      @requested_to_speak_at = new_data['request_to_speak_timestamp'] ? Time.parse(new_data['request_to_speak_timestamp']) : nil
    end
  end
end
