# frozen_string_literal: true

module Discordrb::Events
  # Generic subclass for scheduled events (create/update/delete).
  class ScheduledEventEvent < Event
    # @return [ScheduledEvent] the scheduled event in question.
    attr_reader :scheduled_event

    # @return [Server] the server the scheduled event is from.
    attr_reader :server

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @server = bot.server(data['guild_id'].to_i)
      @scheduled_event = @server&.scheduled_event(data['id'].to_i)
    end
  end

  # Raised when a scheduled event is created.
  class ScheduledEventCreateEvent < ScheduledEventEvent; end

  # Raised when a scheduled event is updated.
  class ScheduledEventUpdateEvent < ScheduledEventEvent; end

  # Raised when a scheduled event is deleted.
  class ScheduledEventDeleteEvent < ScheduledEventEvent
    # @!visibility private
    # @note Override the initializer to account for the deleted event.
    def initialize(data, bot)
      @bot = bot
      @server = bot.server(data['guild_id'].to_i)
      @scheduled_event = Discordrb::ScheduledEvent.new(data, @server, bot)
    end
  end

  # Generic subclass for whenever a user is added to or removed from a scheduled event.
  class ScheduledEventUserEvent < Event
    # @!visibility private
    attr_reader :user_id

    # @!visibility private
    attr_reader :server_id

    # @!visibility private
    attr_reader :scheduled_event_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @user_id = data['user_id'].to_i
      @server_id = data['guild_id'].to_i
      @scheduled_event_id = data['guild_scheduled_event_id'].to_i
    end

    # Get the server the scheduled event in question is from.
    # @return [Server] the server the scheduled event is associated with.
    def server
      @bot.server(@server_id)
    end

    # Get the scheduled event that the user was added to or removed from.
    # @return [ScheduledEvent] the scheduled event that the user was actioned on.
    def scheduled_event
      server.scheduled_event(@scheduled_event_id)
    end

    # Get the user that was added to or removed from the scheduled event.
    # @return [Member, User] the server member that was added to or removed from the
    #   scheduled event, or a user if the member cannot be accessed by the bot.
    def member
      server.member(@user_id) || @bot.user(@user_id)
    end

    alias_method :user, :member
  end

  # Raised when a user id added to a scheduled event.
  class ScheduledEventUserAddEvent < ScheduledEventUserEvent; end

  # Raised when a user id removed from a scheduled event.
  class ScheduledEventUserRemoveEvent < ScheduledEventUserEvent; end

  # Event handler for generic scheduled event events.
  class ScheduledEventEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      return false unless event.is_a?(ScheduledEventEvent)

      [
        matches_all(@attributes[:server], event.server) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:id], event.scheduled_event) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:creator], event.scheduled_event.creator) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:entity_id], event.scheduled_event.entity_id) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:entity_type], event.scheduled_event.entity_type) do |a, e|
          case a
          when Symbol
            Discordrb::ScheduledEvent::ENTITY_TYPES[a] == e
          else
            a == e
          end
        end,

        matches_all(@attributes[:status], event.scheduled_event.status) do |a, e|
          case a
          when Symbol
            Discordrb::ScheduledEvent::STATUSES[a] == e
          else
            a == e
          end
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for :GUILD_SCHEDULED_EVENT_CREATE events.
  class ScheduledEventCreateEventHandler < ScheduledEventEventHandler; end

  # Event handler for :GUILD_SCHEDULED_EVENT_UPDATE events.
  class ScheduledEventUpdateEventHandler < ScheduledEventEventHandler; end

  # Event handler for :GUILD_SCHEDULED_EVENT_DELETE events.
  class ScheduledEventDeleteEventHandler < ScheduledEventEventHandler; end

  # Event handler for generic scheduled event user add and remove events.
  class ScheduledEventUserEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      return false unless event.is_a?(ScheduledEventUserEvent)

      [
        matches_all(@attributes[:user], event.user_id) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:server], event.server_id) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:scheduled_event], event.scheduled_event_id) do |a, e|
          a.resolve_id == e.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for :GUILD_SCHEDULED_EVENT_USER_ADD events.
  class ScheduledEventUserAddEventHandler < ScheduledEventUserEventHandler; end

  # Event handler for :GUILD_SCHEDULED_EVENT_USER_REMOVE events.
  class ScheduledEventUserRemoveEventHandler < ScheduledEventUserEventHandler; end
end
