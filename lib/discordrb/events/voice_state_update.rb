# frozen_string_literal: true

require 'discordrb/events/generic'
require 'discordrb/data'

module Discordrb::Events
  # Event raised when a user's voice state updates.
  class VoiceStateUpdateEvent < Event
    # @return [User] the user whose voice state was updated.
    attr_reader :user

    # @!visibility private
    # @note TODO: remove this in 4.0, since it isn't an actual field that
    #   the gateway sends (nor is it documented).
    attr_reader :token

    # @return [Server] the server that the voice state is from.
    attr_reader :server

    # @return [true, false] whether this voice state's user is muted server-wide.
    attr_reader :mute
    alias_method :mute?, :mute

    # @return [true, false] whether this voice state's user is deafened server-wide.
    attr_reader :deaf
    alias_method :deaf?, :deaf

    # @return [true, false] whether this voice state's user has muted themselves.
    attr_reader :self_mute
    alias_method :self_mute?, :self_mute

    # @return [true, false] whether this voice state's user has deafened themselves.
    attr_reader :self_deaf
    alias_method :self_deaf?, :self_deaf

    # @return [true, false] whether this voice state's user is currently streaming via go-live.
    attr_reader :self_stream
    alias_method :self_stream?, :self_stream

    # @return [true, false] whether this voice state's user currently has their cameria enabled.
    attr_reader :self_video
    alias_method :self_video?, :self_video

    # @return [true, false] whether this voice state's user has been suppressed in the stage channel.
    attr_reader :suppress
    alias_method :suppress?, :suppress

    # @return [Time, nil] the time at when this voice state's user requested to speak in the stage channel.
    attr_reader :requested_to_speak_at

    # @return [String] the ID of the session the voice state is from.
    attr_reader :session_id

    # @return [Channel, nil] the channel that the user is connected to, or `nil` if the user has left
    #   the voice channel.
    attr_reader :channel

    # @return [Channel, nil] the old channel this user was on, or `nil` if the user is newly joining voice.
    attr_reader :old_channel

    # @!visibility private
    def initialize(data, old_channel_id, bot)
      @bot = bot
      @user = bot.user(data['user_id'].to_i)
      @token = data['token']
      @session_id = data['session_id']
      @mute = data['mute']
      @deaf = data['deaf']
      @self_mute = data['self_mute']
      @self_deaf = data['self_deaf']
      @self_video = data['self_video']
      @self_stream = data['self_stream'] || false
      @suppress = data['suppress']
      @requested_to_speak_at = data['request_to_speak_timestamp'] ? Time.parse(data['request_to_speak_timestamp']) : nil
      return unless (@server = bot.server(data['guild_id'].to_i))

      @old_channel = bot.channel(old_channel_id) if old_channel_id
      @channel = bot.channel(data['channel_id'].to_i) if data['channel_id']
    end
  end

  # Event handler for VoiceStateUpdateEvent
  class VoiceStateUpdateEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? VoiceStateUpdateEvent

      [
        matches_all(@attributes[:from], event.user) do |a, e|
          a == case a
               when String
                 e.name
               when Integer
                 e.id
               else
                 e
               end
        end,
        matches_all(@attributes[:mute], event.mute) do |a, e|
          a == if a.is_a? String
                 e.to_s
               else
                 e
               end
        end,
        matches_all(@attributes[:deaf], event.deaf) do |a, e|
          a == if a.is_a? String
                 e.to_s
               else
                 e
               end
        end,
        matches_all(@attributes[:self_mute], event.self_mute) do |a, e|
          a == if a.is_a? String
                 e.to_s
               else
                 e
               end
        end,
        matches_all(@attributes[:self_deaf], event.self_deaf) do |a, e|
          a == if a.is_a? String
                 e.to_s
               else
                 e
               end
        end,
        matches_all(@attributes[:channel], event.channel) do |a, e|
          next unless e # Don't bother if the channel is nil

          a == case a
               when String
                 e.name
               when Integer
                 e.id
               else
                 e
               end
        end,
        matches_all(@attributes[:old_channel], event.old_channel) do |a, e|
          next unless e # Don't bother if the channel is nil

          a == case a
               when String
                 e.name
               when Integer
                 e.id
               else
                 e
               end
        end
      ].reduce(true, &:&)
    end
  end
end
