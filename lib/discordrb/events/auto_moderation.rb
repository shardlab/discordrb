# frozen_string_literal: true

module Discordrb::Events
  # Generic subclass for automod rule events (create/update/delete).
  class AutoModRuleEvent < Event
    # @return [AutoModRule] the automod rule in question.
    attr_reader :automod_rule

    # @return [Server] the server the automod rule is from.
    attr_reader :server

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @server = bot.server(data['guild_id'].to_i)
      @automod_rule = @server.automod_rule(data['id'].to_i)
    end
  end

  # Raised when an automod rule is created.
  class AutoModRuleCreateEvent < AutoModRuleEvent; end

  # Raised when an automod rule is updated.
  class AutoModRuleUpdateEvent < AutoModRuleEvent; end

  # Raised when an automod rule is deleted.
  class AutoModRuleDeleteEvent < AutoModRuleEvent
    # @!visibility private
    # @note Override the initializer to account for the deleted rule.
    def initialize(data, bot)
      @bot = bot
      @server = bot.server(data['guild_id'].to_i)
      @automod_rule = Discordrb::AutoModRule.new(data, @server, bot)
    end
  end

  # Event handler for generic auto-moderation rule events.
  class AutoModRuleEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      return false unless event.is_a? AutoModRuleEvent

      [
        matches_all(@attributes[:server], event.server) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:id], event.automod_rule) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:creator], event.automod_rule.creator) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:name], event.automod_rule.name) do |a, e|
          case a
          when String, Symbol
            a.to_s == e
          when Regexp
            e.match?(e)
          end
        end,

        matches_all(@attributes[:event_type], event.automod_rule.event_type) do |a, e|
          case a
          when Symbol
            Discordrb::AutoModRule::EVENT_TYPES[a] == e
          when Integer
            a == e
          end
        end,

        matches_all(@attributes[:trigger_type], event.automod_rule.trigger.type) do |a, e|
          case a
          when Symbol
            Discordrb::AutoModRule::Trigger::TYPES[a] == e
          when Integer
            a == e
          end
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for :AUTO_MODERATION_RULE_CREATE events.
  class AutoModRuleCreateEventHandler < AutoModRuleEventHandler; end

  # Event handler for :AUTO_MODERATION_RULE_UPDATE events.
  class AutoModRuleUpdateEventHandler < AutoModRuleEventHandler; end

  # Event handler for :AUTO_MODERATION_RULE_DELETE events.
  class AutoModRuleDeleteEventHandler < AutoModRuleEventHandler; end

  # This event is raised whenever an automod rule is triggered.
  class AutoModActionEvent < Event
    # @!visibility private
    attr_reader :server_id, :rule_id, :user_id, :channel_id

    # @return [AutoModRule::Action] the action which was taken.
    attr_reader :action

    # @return [String] the user-generated content that triggered the automod rule.
    attr_reader :content

    # @return [Integer] the trigger type of the automod rule that was triggered.
    attr_reader :trigger_type

    # @return [String, nil] the keyword or phrase which triggered the automod rule.
    attr_reader :matched_keyword

    # @return [String, nil] the substring in content that triggered the automod rule.
    attr_reader :matched_content

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @rule_id = data['rule_id'].to_i
      @user_id = data['user_id'].to_i
      @server_id = data['guild_id'].to_i
      @channel_id = data['channel_id']&.to_i
      @message_id = data['message_id']&.to_i
      @alert_message_id = data['alert_system_message_id']&.to_i

      @content = data['content']
      @trigger_type = data['rule_trigger_type']
      @matched_keyword = data['matched_keyword']
      @matched_content = data['matched_content']
      @action = Discordrb::AutoModRule::Action.new(data['action'], bot)
    end

    # @return [Server] the server this event originates from.
    def server
      @bot.server(@server_id)
    end

    # @return [Channel, nil] the channel in which user content was posted.
    def channel
      @bot.channel(@channel_id) if @channel_id
    end

    # @return [AutoModRule] the automod rule that was triggered.
    def automod_rule
      server.automod_rule(@rule_id)
    end

    # @return [User, Member] the user or member which generated the content that triggered the automod rule.
    #   Should usually be a member unless the member was recently removed from the server.
    def user
      server.member(@user_id) || @bot.user(@user_id)
    end

    alias_method :member, :user

    # @return [Message, nil] the message that contains the user-generated content which triggered the automod rule.
    def message
      @message_id ? (@message ||= channel.load_message(@message_id)) : nil
    end

    # @return [Message, nil] the system generated automod message posted as a result of this action.
    def alert_message
      return nil unless action.send_alert_message? && @alert_message_id

      @alert_message ||= action.alert_channel&.load_message(@alert_message_id)
    end
  end

  # Event handler for auto-moderation rule execution events.
  class AutoModActionEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      return false unless event.is_a? AutoModActionEvent

      [
        matches_all(@attributes[:user], event.user_id) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:server], event.server_id) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:channel], event.channel_id) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:automod_rule], event.rule_id) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:content], event.content) do |a, e|
          case a
          when String
            a == e
          when Regexp
            e&.match?(a)
          end
        end,

        matches_all(@attributes[:trigger_type], event.trigger_type) do |a, e|
          case a
          when Symbol
            Discordrb::AutoModRule::Trigger::TYPES[a] == e
          when Integer
            a == e
          end
        end,

        matches_all(@attributes[:matched_content], event.matched_content) do |a, e|
          case a
          when String
            a == e
          when Regexp
            e&.match?(a)
          end
        end,

        matches_all(@attributes[:matched_keyword], event.matched_keyword) do |a, e|
          case a
          when String
            a == e
          when Regexp
            e&.match?(a)
          end
        end,

        matches_all(@attributes[:event_type], event.automod_rule.event_type) do |a, e|
          case a
          when Symbol
            Discordrb::AutoModRule::EVENT_TYPES[a] == e
          when Integer
            a == e
          end
        end,

        matches_all(@attributes[:action_type], event.action.type) do |a, e|
          case a
          when Symbol
            Discordrb::AutoModRule::Action::TYPES[a] == e
          when Integer
            a == e
          end
        end
      ].reduce(true, &:&)
    end
  end
end
