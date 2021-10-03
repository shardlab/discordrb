# frozen_string_literal: true

require 'discordrb/events/guilds'
require 'discordrb/data'

module Discordrb::Events
  # Generic subclass for server emoji events (create/update/delete)
  class ServerEmojiEvent < ServerEvent
    # @return [Server] the server in question.
    attr_reader :server

    def initialize(server, bot)
      super(nil, bot)
      @server = server
    end

    # HACK: this allows us to subclass ServerEvent to avoid breaking heirarchy-dependent usage
    def init_server(_data, _bot)
      nil
    end
  end

  # Emoji is created/deleted/updated
  class ServerEmojiChangeEvent < ServerEmojiEvent
    # @return [Array<Emoji>] array of emojis.
    attr_reader :emoji

    def initialize(server, data, bot)
      super(server, bot)
      process_emoji(data)
    end

    # @!visibility private
    def process_emoji(data)
      @emoji = data['emojis'].map do |e|
        server.emoji[e['id']]
      end
    end
  end

  # Generic event helper for when an emoji is either created or deleted
  class ServerEmojiCDEvent < ServerEmojiEvent
    # @return [Emoji] the emoji data.
    attr_reader :emoji

    def initialize(server, emoji, bot)
      super(server, bot)
      @emoji = emoji
    end
  end

  # Emoji is created
  class ServerEmojiCreateEvent < ServerEmojiCDEvent; end

  # Emoji is deleted
  class ServerEmojiDeleteEvent < ServerEmojiCDEvent; end

  # Emoji is updated
  class ServerEmojiUpdateEvent < ServerEmojiEvent
    # @return [Emoji, nil] the emoji data before the event.
    attr_reader :old_emoji

    # @return [Emoji, nil] the updated emoji data.
    attr_reader :emoji

    def initialize(server, old_emoji, emoji, bot)
      super(server, bot)
      @old_emoji = old_emoji
      @emoji = emoji
    end
  end

  # Generic event handler for emoji events
  class ServerEmojiEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? ServerEmojiEvent

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

  # Event handler for {ServerEmojiChangeEvent}
  class ServerEmojiChangeEventHandler < ServerEmojiEventHandler; end

  # Generic handler for emoji create and delete
  class ServerEmojiCDEventHandler < ServerEmojiEventHandler
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
end
