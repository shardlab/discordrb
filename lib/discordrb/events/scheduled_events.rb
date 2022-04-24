# frozen_string_literal: true

require 'discordrb/events/generic'
require 'discordrb/data'

module Discordrb::Events
  # Raised when a scheduled event is created on a server
  class ServerScheduledEventCreateEvent < Event
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

      scheduled_event_id = data['guild_scheduled_event_id'].to_i
      @scheduled_event = @server.scheduled_events.find { |event| event.id == scheduled_event_id }
    end
  end

  # Event handler for ServerScheduledEventCreateEvent
  class ServerScheduledEventCreateEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? ServerScheduledEventCreateEvent

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

  # Raised when a scheduled event is deleted from a server
  class ServerScheduledEventDeleteEvent < Event
    # @return [Integer] the ID of the scheduled event that got deleted.
    attr_reader :id

    # @return [Server] the server on which the scheduled event got deleted.
    attr_reader :server

    def initialize(data, bot)
      @bot = bot

      # The scheduled event should already be deleted from the server's list
      # by the time we create this event, so we'll create a temporary
      # scheduled event object for event consumers to use.
      @id = data['guild_scheduled_event_id'].to_i
      @server = bot.server(data['guild_id'].to_i)
    end
  end

  # EventHandler for ServerScheduledEventDeleteEvent
  class ServerScheduledEventDeleteEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? ServerScheduledEventDeleteEvent

      [
        matches_all(@attributes[:id], event.id) do |a, e|
          a.resolve_id == e.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Event raised when a scheduled event updates on a server
  class ServerScheduledEventUpdateEvent < ServerScheduledEventCreateEvent; end

  # Event handler for ServerScheduledEventUpdateEvent
  class ServerScheduledEventUpdateEventHandler < ServerScheduledEventCreateEventHandler; end

  # Raised when a user is added to a scheduled event.
  class ServerScheduledEventUserAddEvent < Event
    # @return [ScheduledEvent] the scheduled event that the user was added to
    attr_reader :scheduled_event

    # @return [User] the user that was added to the scheduled event
    attr_reader :user

    # @return [Server] the server in which the scheduled event exists
    attr_reader :server

    # @!attribute [r] name
    #   @return [String] the scheduled event's name
    #   @see ScheduledEvent#name
    delegate :name, to: :scheduled_event

    def initialize(data, bot)
      @bot = bot

      @server = bot.server(data['guild_id'].to_i)
      return unless @server

      scheduled_event_id = data['guild_scheduled_event_id'].to_i
      @scheduled_event = @server.scheduled_events.find { |event| event.id == scheduled_event_id }

      @user = @bot.user(data['user_id'].to_i)
    end
  end

  # Event handler for ServerScheduledEventUserAddEvent.
  class ServerScheduledEventUserAddEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? ServerScheduledEventUserAddEvent

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

  # Raised when a user is removed from a scheduled event.
  class ServerScheduledEventUserRemoveEvent < Event
    # @return [ScheduledEvent] the scheduled event that the user was removed from
    attr_reader :scheduled_event

    # @return [User] the user that was removed from the scheduled event
    attr_reader :user

    # @return [Server] the server in which the scheduled event exists
    attr_reader :server

    # @!attribute [r] name
    #   @return [String] the scheduled event's name
    #   @see ScheduledEvent#name
    delegate :name, to: :scheduled_event

    def initialize(data, bot)
      @bot = bot

      @server = bot.server(data['guild_id'].to_i)
      return unless @server

      scheduled_event_id = data['guild_scheduled_event_id'].to_i
      @scheduled_event = @server.scheduled_events.find { |event| event.id == scheduled_event_id }

      @user = @bot.user(data['user_id'].to_i)
    end
  end

  # Event handler for ServerScheduledEventUserRemoveEvent.
  class ServerScheduledEventUserRemoveEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? ServerScheduledEventUserRemoveEvent

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
