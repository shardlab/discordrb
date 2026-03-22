# frozen_string_literal: true

require 'discordrb/events/generic'
require 'discordrb/data'

module Discordrb::Events
  # Generic subclass for server events (create/update/delete)
  class ServerEvent < Event
    # @return [Server] the server in question.
    attr_reader :server

    # @!visibility private
    def initialize(data, bot)
      @bot = bot

      init_server(data, bot)
    end

    # Initializes this event with server data. Should be overwritten in case the server doesn't exist at the time
    # of event creation (e. g. {ServerDeleteEvent})
    def init_server(data, bot)
      @server = bot.server(data['id'].to_i)
    end
  end

  # Generic event handler for member events
  class ServerEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? ServerEvent

      [
        matches_all(@attributes[:server], event.server) do |a, e|
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

  # Server is created
  # @see Discordrb::EventContainer#server_create
  class ServerCreateEvent < ServerEvent; end

  # Event handler for {ServerCreateEvent}
  class ServerCreateEventHandler < ServerEventHandler; end

  # Server is updated (e.g. name changed)
  # @see Discordrb::EventContainer#server_update
  class ServerUpdateEvent < ServerEvent; end

  # Event handler for {ServerUpdateEvent}
  class ServerUpdateEventHandler < ServerEventHandler; end

  # Server is deleted, the server was left because the bot was kicked, or the
  # bot made itself leave the server.
  # @see Discordrb::EventContainer#server_delete
  class ServerDeleteEvent < ServerEvent
    # @return [Integer] The ID of the server that was left.
    attr_reader :server

    # @!visibility private
    # @note Override init_server to account for the deleted server
    def init_server(data, _bot)
      @server = data['id'].to_i
    end
  end

  # Event handler for {ServerDeleteEvent}
  class ServerDeleteEventHandler < ServerEventHandler; end

  # Emoji is created/deleted/updated
  class ServerEmojiChangeEvent < ServerEvent
    # @return [Server] the server in question.
    attr_reader :server

    # @return [Array<Emoji>] array of emojis.
    attr_reader :emoji

    # @!visibility private
    def initialize(server, data, bot)
      @bot = bot
      @server = server
      process_emoji(data)
    end

    # @!visibility private
    def process_emoji(data)
      @emoji = data['emojis'].map do |e|
        @server.emoji[e['id']]
      end
    end
  end

  # Generic event helper for when an emoji is either created or deleted
  class ServerEmojiCDEvent < ServerEvent
    # @return [Server] the server in question.
    attr_reader :server

    # @return [Emoji] the emoji data.
    attr_reader :emoji

    # @!visibility private
    def initialize(server, emoji, bot)
      @bot = bot
      @emoji = emoji
      @server = server
    end
  end

  # Emoji is created
  class ServerEmojiCreateEvent < ServerEmojiCDEvent; end

  # Emoji is deleted
  class ServerEmojiDeleteEvent < ServerEmojiCDEvent; end

  # Emoji is updated
  class ServerEmojiUpdateEvent < ServerEvent
    # @return [Server] the server in question.
    attr_reader :server

    # @return [Emoji, nil] the emoji data before the event.
    attr_reader :old_emoji

    # @return [Emoji, nil] the updated emoji data.
    attr_reader :emoji

    # @!visibility private
    def initialize(server, old_emoji, emoji, bot)
      @bot = bot
      @old_emoji = old_emoji
      @emoji = emoji
      @server = server
    end
  end

  # Event handler for {ServerEmojiChangeEvent}
  class ServerEmojiChangeEventHandler < ServerEventHandler; end

  # Generic handler for emoji create and delete
  class ServerEmojiCDEventHandler < ServerEventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? ServerEmojiCDEvent

      [
        matches_all(@attributes[:server], event.server) do |a, e|
          a == case a
               when String
                 e.name
               when Integer
                 e.id
               else
                 e
               end
        end,
        matches_all(@attributes[:id], event.emoji.id) { |a, e| a.resolve_id == e.resolve_id },
        matches_all(@attributes[:name], event.emoji.name) { |a, e| a == e }
      ].reduce(true, &:&)
    end
  end

  # Event handler for {ServerEmojiCreateEvent}
  class ServerEmojiCreateEventHandler < ServerEmojiCDEventHandler; end

  # Event handler for {ServerEmojiDeleteEvent}
  class ServerEmojiDeleteEventHandler < ServerEmojiCDEventHandler; end

  # Event handler for {ServerEmojiUpdateEvent}
  class ServerEmojiUpdateEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? ServerEmojiUpdateEvent

      [
        matches_all(@attributes[:server], event.server) do |a, e|
          a == case a
               when String
                 e.name
               when Integer
                 e.id
               else
                 e
               end
        end,
        matches_all(@attributes[:id], event.old_emoji.id) { |a, e| a.resolve_id == e.resolve_id },
        matches_all(@attributes[:old_name], event.old_emoji.name) { |a, e| a == e },
        matches_all(@attributes[:name], event.emoji.name) { |a, e| a == e }
      ].reduce(true, &:&)
    end
  end

  # Raised whenever an audit log entry is created.
  class AuditLogEntryCreateEvent < Event
    # @return [Server] the server of the audit log event.
    attr_reader :server

    # @return [AuditLogs::Entry] the entry of the audit log event.
    attr_reader :entry

    # @return [Integer] the raw action type of the audit log entry.
    attr_reader :action

    # @return [Integer] the ID of the user or bot that made the entry.
    attr_reader :user_id

    # @return [Integer, nil] the ID of the affected webhook, user, etc.
    attr_reader :target_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @action = data['action_type']
      @user_id = data['user_id']&.to_i
      @target_id = data['target_id']&.to_i
      @server = bot.server(data['guild_id'].to_i)
      @entry = Discordrb::AuditLogs::Entry.new(nil, @server, @bot, data)
    end
  end

  # Event handler for GUILD_AUDIT_LOG_ENTRY_CREATE events.
  class AuditLogEntryCreateEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(AuditLogEntryCreateEvent)

      [
        matches_all(@attributes[:action], event) do |a, e|
          case a
          when Numeric
            a == e.action
          when String, Symbol
            a.to_sym == e.entry.action
          end
        end,

        matches_all(@attributes[:reason], event.entry) do |a, e|
          if e.reason
            case a
            when String
              a == e.reason
            when Regexp
              a.match?(e.reason)
            end
          end
        end,

        matches_all(@attributes[:user], event.user_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:server], event.server) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:target], event.target_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end
end
