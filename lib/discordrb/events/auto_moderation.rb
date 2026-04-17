# frozen_string_literal: true

require 'discordrb/data'
require 'discordrb/events/generic'

module Discordrb::Events
  # Generic superclass for auto moderation rule events.
  class AutoModRuleEvent < Event
    # @return [Server] the server associated with the event.
    attr_reader :server

    # @return [AutoModRule] the auto moderation rule associated with the event.
    attr_reader :automod_rule

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @server = bot.server(data['guild_id'].to_i)
      @automod_rule = @server.automod_rule(data['id'].to_i)
    end
  end

  # Raised whenever an auto moderation rule is created.
  class AutoModRuleCreateEvent < AutoModRuleEvent; end

  # Raised whenever an auto moderation rule is updated.
  class AutoModRuleUpdateEvent < AutoModRuleEvent; end

  # Raised whenever an auto moderation rule is deleted.
  class AutoModRuleDeleteEvent < AutoModRuleEvent
    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @server = bot.server(data['guild_id'].to_i)
      @automod_rule = Discordrb::AutoModRule.new(data, @server, @bot)
    end
  end

  # Raised whenever an auto moderation rule is triggered and an action is executed.
  class AutoModRuleExecutionEvent < Event
    # @return [Action] the action that was executed.
    attr_reader :action

    # @return [String] the message content associated with the event.
    attr_reader :content

    # @return [Integer] the ID of the user who created the offending content.
    attr_reader :user_id

    # @return [Integer] the ID of the server where the offending content was made.
    attr_reader :server_id

    # @return [Integer, nil] the ID of the message containing the offending content.
    attr_reader :message_id

    # @return [Integer, nil] the ID of the channel where the offending content was made.
    attr_reader :channel_id

    # @return [Integer] the trigger type of the auto moderation rule that was triggered.
    attr_reader :trigger_type

    # @return [Integer] the ID of the auto moderation rule that's associated with the event.
    attr_reader :automod_rule_id

    # @return [String] the configured word or phrase that was matched by the auto moderation rule.
    attr_reader :matched_keyword

    # @return [String] the specific substring in the content that triggered the auto moderation rule.
    attr_reader :matched_content

    # @return [Integer, nil] the ID of any auto moderation alert messages that were posted as a result.
    attr_reader :alert_message_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @content = data['content']
      @user_id = data['user_id']&.to_i
      @server_id = data['guild_id']&.to_i
      @channel_id = data['channel_id']&.to_i
      @message_id = data['message_id']&.to_i
      @automod_rule_id = data['rule_id']&.to_i
      @trigger_type = data['rule_trigger_type']
      @matched_keyword = data['matched_keyword']
      @matched_content = data['matched_content']
      @alert_message_id = data['alert_system_message_id']&.to_i
      @action = Discordrb::AutoModRule::Action.new(data['action'], @bot)
    end

    # Get the user who made the offending content.
    # @return [User] The user who made the offending content.
    def user
      @bot.user(@user_id)
    end

    # Get the server where the offending content was made.
    # @return [Server] The server containing the offending content.
    def server
      @bot.server(@server_id)
    end

    # Get the channel where the offending content was made.
    # @return [Channel, nil] The channel containing the offending content.
    def channel
      @bot.channel(@channel_id)
    end

    # Get the auto moderation rule associated with the event.
    # @return [AutoModRule] The auto moderation rule associated with the event.
    def automod_rule
      server.automod_rule(@automod_rule_id)
    end

    # Get the message which contains the offending content, if any.
    # @return [Message, nil] The message containing the offending content, or `nil`.
    def message
      @message ||= (channel&.message(@message_id) if @message_id)
    end
  end

  # Generic event handler for auto moderation rule events.
  class AutoModRuleEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(AutoModRuleEvent)

      [
        matches_all(@attributes[:server], event.server) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:id], event.automod_rule) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:creator], event.automod_rule) do |a, e|
          a.resolve_id == e.creator.id
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

  # Event handler for :AUTO_MODERATION_ACTION_EXECUTION events.
  class AutoModRuleExecutionEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(AutoModActionEvent)

      [
        matches_all(@attributes[:content], event.content) do |a, e|
          case a
          when String
            a == e
          when Regexp
            e&.match?(a)
          end
        end,

        matches_all(@attributes[:action_type], event.action.type) do |a, e|
          case a
          when Symbol, String
            Discordrb::AutoModRule::Action::TYPES[a.to_sym] == e
          when Integer
            a == e
          end
        end,

        matches_all(@attributes[:trigger_type], event.trigger_type) do |a, e|
          case a
          when Symbol, String
            Discordrb::AutoModRule::Trigger::TYPES[a.to_sym] == e
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

        matches_all(@attributes[:user], event.user_id) { |a, e| a&.resolve_id == e },
        matches_all(@attributes[:server], event.server_id) { |a, e| a&.resolve_id == e },
        matches_all(@attributes[:channel], event.channel_id) { |a, e| a&.resolve_id == e },
        matches_all(@attributes[:automod_rule], event.automod_rule_id) { |a, e| a&.resolve_id == e }
      ].reduce(true, &:&)
    end
  end
end
