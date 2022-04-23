# frozen_string_literal: true

require 'discordrb/events/generic'
require 'discordrb/data'

module Discordrb::Events
  # Raised when a scheduled event is created on a server
  class ScheduledEventCreateEvent < Event
    # @return [ScheduledEvent] the scheduled event that got created
    attr_reader :scheduled_event

    # @return [Server] the server in which the scheduled event got created
    attr_reader :server

    # @!attribute [r] name
    #   @return [String] this scheduled event's name
    #   @see ScheduledEvent#name
    delegate :name, to: :scheduled_event

    def initialize(data, bot)
      @bot = bot

      @server = bot.server(data['guild_id'].to_i)
      return unless @server

      scheduled_event_id = data['scheduled_event']['id'].to_i
      @scheduled_event = @server.scheduled_events.find { |event| event.id == scheduled_event_id }
    end
  end

  # Event handler for ScheduledEventCreateEvent
  class ScheduledEventCreateEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? ScheduledEventCreateEvent

      [
        matches_all(@attributes[:name], event.name) do |a, e|
          a == if a.is_a? String
                 e.to_s
               else
                 e
               end
        end
      ].reduce(true, &:&)
    end
  end
end
