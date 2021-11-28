# frozen_string_literal: true

require 'discordrb/events/generic'
require 'discordrb/data'

module Discordrb::Events
  # Event raised when a guild's voice guild is updating.
  # Sent when initially connecting to voice and when a voice instance fails
  # over to a new guild.
  # This event is exposed for use with library agnostic interfaces like telecom and
  # lavalink.
  class VoiceGuildUpdateEvent < Event
    # @return [String] The voice connection token
    attr_reader :token

    # @return [Guild] The guild this update is for.
    attr_reader :guild

    # @return [String] The voice guild host.
    attr_reader :endpoint

    def initialize(data, bot)
      @bot = bot

      @token = data[:token]
      @endpoint = data[:endpoint]
      @guild = bot.guild(data[:guild_id])
    end
  end

  # Event handler for VoiceGuildUpdateEvent
  class VoiceGuildUpdateEventHandler < EventHandler
    def matches?(event)
      return false unless event.is_a? VoiceGuildUpdateEvent

      [
        matches_all(@attributes[:from], event.guild) do |a, e|
          a == if a.is_a? String
                 e.name
               else
                 e
               end
        end
      ]
    end
  end
end
