# frozen_string_literal: true

module Discordrb::Events
  # Raised when a thread is created
  class ThreadCreateEvent < Event
    # @return [Channel] the thread in question.
    attr_reader :thread

    delegate :name, :server, :owner, :parent_channel, :thread_metadata, to: :thread

    def initialize(data, bot)
      @bot = bot
      @thread = data.is_a?(Discordrb::Channel) ? data : bot.channel(data['id'].to_i)
    end
  end

  # Event handler for ChannelCreateEvent
  class ThreadCreateEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? ThreadCreateEvent

      [
        matches_all(@attributes[:name], event.name) do |a, e|
          a == if a.is_a? String
                 e.to_s
               else
                 e
               end
        end,
        matches_all(@attributes[:server], event.server) do |a, e|
          a.resolve_id == e.resolve_id
        end,
        matches_all(@attributes[:invitable], event.thread.invitable) do |a, e|
          a == e
        end,
        matches_all(@attributes[:owner], event.thread.owner) do |a, e|
          a.resolve_id == e.resolve_id
        end,
        matches_all(@attributes[:channel], event.thread.parent) do |a, e|
          a.resolve_id == e.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Raised when a thread is updated (e.g. name changes)
  class ThreadUpdateEvent < ThreadCreateEvent; end

  # Event handler for ThreadUpdateEvent
  class ThreadUpdateEventHandler < ThreadCreateEventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? ThreadUpdateEvent

      super
    end
  end

  # Raised when members are added or removed from a thread.
  class ThreadMembersUpdateEvent < Event
    # @return [Channel]
    attr_reader :thread

    # @return [Array<Member, User>]
    attr_reader :added_members

    # @return [Array<Integer>]
    attr_reader :removed_member_ids

    # @return [Integer]
    attr_reader :member_count

    delegate :name, :server, :owner, :parent_channel, :thread_metadata, to: :thread

    def initialize(data, bot)
      @bot = bot
      @thread = data.is_a?(Discordrb::Channel) ? data : bot.channel(data['id'].to_i)
      @added_members = data['added_members']&.map do |member|
        data['guild_id'] ? bot.member(data['guild_id'], member['user_id']) : bot.user(member['user_id'])
      end || []
      @removed_member_ids = data['removed_member_ids']&.map(&:resolve_id) || []
      @member_count = data['member_count']
    end
  end

  # Event handler for ThreadMembersUpdateEvent
  class ThreadMembersUpdateEventHandler < ThreadCreateEventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? ThreadMembersUpdateEvent

      super
    end
  end
end
