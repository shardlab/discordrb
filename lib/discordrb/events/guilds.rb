# frozen_string_literal: true

require 'discordrb/events/generic'
require 'discordrb/data'

module Discordrb::Events
  # Generic subclass for guild events (create/update/delete)
  class GuildEvent < Event
    # @return [Guild] the guild in question.
    attr_reader :guild

    def initialize(data, bot)
      @bot = bot

      init_guild(data, bot)
    end

    # Initializes this event with guild data. Should be overwritten in case the guild doesn't exist at the time
    # of event creation (e. g. {GuildDeleteEvent})
    def init_guild(data, bot)
      @guild = bot.guild(data[:id].to_i)
    end
  end

  # Generic event handler for member events
  class GuildEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? GuildEvent

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
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

  # Guild is created
  # @see Discordrb::EventContainer#guild_create
  class GuildCreateEvent < GuildEvent; end

  # Event handler for {GuildCreateEvent}
  class GuildCreateEventHandler < GuildEventHandler; end

  # Guild is updated (e.g. name changed)
  # @see Discordrb::EventContainer#guild_update
  class GuildUpdateEvent < GuildEvent; end

  # Event handler for {GuildUpdateEvent}
  class GuildUpdateEventHandler < GuildEventHandler; end

  # Guild is deleted, the guild was left because the bot was kicked, or the
  # bot made itself leave the guild.
  # @see Discordrb::EventContainer#guild_delete
  class GuildDeleteEvent < GuildEvent
    # @return [Integer] The ID of the guild that was left.
    attr_reader :guild

    # Override init_guild to account for the deleted guild
    def init_guild(data, _bot)
      @guild = data[:id].to_i
    end
  end

  # Event handler for {GuildDeleteEvent}
  class GuildDeleteEventHandler < GuildEventHandler; end

  # Emoji is created/deleted/updated
  class GuildEmojiChangeEvent < GuildEvent
    # @return [Guild] the guild in question.
    attr_reader :guild

    # @return [Array<Emoji>] array of emojis.
    attr_reader :emoji

    def initialize(guild, data, bot)
      @bot = bot
      @guild = guild
      process_emoji(data)
    end

    # @!visibility private
    def process_emoji(data)
      @emoji = data[:emojis].map do |e|
        @guild.emoji[e[:id]]
      end
    end
  end

  # Generic event helper for when an emoji is either created or deleted
  class GuildEmojiCDEvent < GuildEvent
    # @return [Guild] the guild in question.
    attr_reader :guild

    # @return [Emoji] the emoji data.
    attr_reader :emoji

    def initialize(guild, emoji, bot)
      @bot = bot
      @emoji = emoji
      @guild = guild
    end
  end

  # Emoji is created
  class GuildEmojiCreateEvent < GuildEmojiCDEvent; end

  # Emoji is deleted
  class GuildEmojiDeleteEvent < GuildEmojiCDEvent; end

  # Emoji is updated
  class GuildEmojiUpdateEvent < GuildEvent
    # @return [Guild] the guild in question.
    attr_reader :guild

    # @return [Emoji, nil] the emoji data before the event.
    attr_reader :old_emoji

    # @return [Emoji, nil] the updated emoji data.
    attr_reader :emoji

    def initialize(guild, old_emoji, emoji, bot)
      @bot = bot
      @old_emoji = old_emoji
      @emoji = emoji
      @guild = guild
    end
  end

  # Event handler for {GuildEmojiChangeEvent}
  class GuildEmojiChangeEventHandler < GuildEventHandler; end

  # Generic handler for emoji create and delete
  class GuildEmojiCDEventHandler < GuildEventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? GuildEmojiCDEvent

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
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

  # Event handler for {GuildEmojiCreateEvent}
  class GuildEmojiCreateEventHandler < GuildEmojiCDEventHandler; end

  # Event handler for {GuildEmojiDeleteEvent}
  class GuildEmojiDeleteEventHandler < GuildEmojiCDEventHandler; end

  # Event handler for {GuildEmojiUpdateEvent}
  class GuildEmojiUpdateEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? GuildEmojiUpdateEvent

      [
        matches_all(@attributes[:guild], event.guild) do |a, e|
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
