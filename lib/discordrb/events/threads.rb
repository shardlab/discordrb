# frozen_string_literal: true

require 'discordrb/data'
require 'discordrb/events/generic'

module Discordrb::Events
  # Generic superclass for thread events.
  class ThreadEvent < Event
    # @return [Integer] the ID of the thread associated with the event.
    attr_reader :id

    # @return [Integer] the type of the thread associated with the event.
    attr_reader :type

    # @return [Server] the server of the thread associated with the event.
    attr_reader :server

    # @return [Integer] the parent channel ID of the thread associated with
    #   the event.
    attr_reader :parent_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      @type = data['type']
      @parent_id = data['parent_id']&.to_i
      @server = bot.server(data['guild_id'].to_i)
    end

    # Get the thread channel associated with the event.
    # @return [Channel] The thread channel associated with the event.
    def channel
      @bot.channel(@id)
    end

    alias_method :thread, :channel

    # Get the parent channel of the thread associated with the event.
    # @return [Channel] The parent channel of the thread in question.
    def parent
      @bot.channel(@parent_id)
    end

    # Check if the thread associated with the event was a news thread.
    # @return [true, false] Whether or not the thread in question was a news thread.
    def news_thread?
      @type == Discordrb::Channel::TYPES[:news_thread]
    end

    # Check if the thread associated with the event was a public thread.
    # @return [true, false] Whether or not the thread in question was a public thread.
    def public_thread?
      @type == Discordrb::Channel::TYPES[:public_thread]
    end

    # Check if the thread associated with the event was a private thread.
    # @return [true, false] Whether or not the thread in question was a private thread.
    def private_thread?
      @type == Discordrb::Channel::TYPES[:private_thread]
    end
  end

  # Raised whenever a thread channel is created.
  class ThreadCreateEvent < ThreadEvent; end

  # Raised whenever a thread channel is updated.
  class ThreadUpdateEvent < ThreadEvent; end

  # Raised whenever a thread channel is deleted.
  class ThreadDeleteEvent < ThreadEvent; undef :thread; end

  # Generic event handler for thread events.
  class ThreadEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(ThreadEvent)

      [
        matches_all(@attributes[:id], event.id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:server], event.server) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:parent], event.parent_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:type], event.type) do |a, e|
          case a
          when String, Symbol
            Discordrb::Channel::TYPES[a.to_sym] == e
          else
            a == e
          end
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for :THREAD_CREATE events.
  class ThreadCreateEventHandler < ThreadEventHandler; end

  # Event handler for :THREAD_UPDATE events.
  class ThreadUpdateEventHandler < ThreadEventHandler; end

  # Event handler for :THREAD_DELETE events.
  class ThreadDeleteEventHandler < ThreadEventHandler; end

  # Generic superclass for thread member events.
  class ThreadMemberEvent < Event
    # @return [Member] the member associated with the event.
    attr_reader :member
    alias user member

    # @return [Channel] the thread associated with the event.
    attr_reader :channel
    alias thread channel

    # @return [Integer] the ID of the member associated with the event.
    attr_reader :user_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @member = data['member']
      @user_id = @member.resolve_id
      @channel = bot.channel(data['id'].to_i)
    end
  end

  # Raised whenever a member is added to a thread.
  class ThreadMemberAddEvent < ThreadMemberEvent; end

  # Raised whenever a member is removed from a thread.
  class ThreadMemberRemoveEvent < ThreadMemberEvent
    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @user_id = data['user_id'].to_i
      @channel = bot.channel(data['id'].to_i)
    end

    # Get the member who was removed from the thread.
    # @return [Member, User] The member that was removed from the thread.
    def member
      @member ||= (@channel.server.member(@user_id) || @bot.user(@user_id))
    end
  end

  # Generic event handler for thread member events.
  class ThreadMemberEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(ThreadMemberEvent)

      [
        matches_all(@attributes[:server], event.channel.server) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:member] || @attributes[:user], event.user_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:channel] || @attributes[:thread], event.channel) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for :THREAD_MEMBERS_UPDATE events.
  class ThreadMemberAddEventHandler < ThreadMemberEventHandler; end

  # Event handler for :THREAD_MEMBERS_UPDATE events.
  class ThreadMemberRemoveEventHandler < ThreadMemberEventHandler; end
end
