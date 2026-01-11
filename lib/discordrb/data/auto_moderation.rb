# frozen_string_literal: true

module Discordrb
  # An auto moderation rule on a server.
  class AutoModRule
    include IDObject

    # Mapping of event types.
    EVENT_TYPES = {
      message_send: 1,
      member_update: 2
    }.freeze

    # @return [String] the name of the auto moderation rule.
    attr_reader :name

    # @return [Trigger] the trigger data of the auto moderation rule.
    attr_reader :trigger

    # @return [Array<Action>] the actions of the auto moderation rule.
    attr_reader :actions

    # @return [Integer] the event (context) type of the auto moderation rule.
    attr_reader :event_type

    # @return [true, false] whether or not the auto moderation rule is enabled.
    attr_reader :enabled
    alias_method :enabled?, :enabled

    # @!visibility private
    def initialize(data, server, bot)
      @bot = bot
      @server = server
      @id = data['id'].to_i
      @creator_id = data['creator_id'].to_i

      # Set the rest of the mutable data in the method.
      update_data(data)
    end

    # Get the user who was responsible for creating the auto moderation rule.
    # @return [User] The user who was responsible for creating the auto moderation rule.
    def creator
      @bot.user(@creator_id) if @creator_id
    end

    # Get the roles that will be ignored by the auto moderation rule.
    # @return [Array<Role>] The roles that will be ignored by the auto moderation rule.
    def exempt_roles
      @exempt_roles.filter_map { |id| @server.role(id) }
    end

    # Get the channels that will be ignored by the auto moderation rule.
    # @return [Array<Channel>] The channels that will be ignored by the auto moderation rule.
    def exempt_channels
      @exempt_channels.filter_map { |id| @bot.channel(id) }
    end

    # @!method message_send?
    #   @return [true, false] whether or not the auto moderation rule will trigger when a message is sent or edited.
    # @!method member_update?
    #   @return [true, false] whether or not the auto moderation rule will trigger when a member edits their profile.
    EVENT_TYPES.each do |name, value|
      define_method("#{name}?") do
        @event_type == value
      end
    end

    # Edit the properties of the auto moderation rule.
    # @param name [String] The new name of the auto moderation rule.
    # @param trigger [Trigger, #to_h] The new trigger of the auto moderation rule.
    # @param event_type [Symbol, Integer] The new event type of the auto moderation rule.
    # @param actions [Array<#to_h, Action>] The new actions of the auto moderation rule.
    # @param enabled [true, false] Whether or not the auto moderation rule should be enabled.
    # @param exempt_roles [Array<Integer, String, Role>] The new members to ignore who have any of these roles.
    # @param exempt_channels [Array<Integer, String, Channel>] The channels where newly created messages should be ignored.
    # @param reason [String, nil] The reason to show in the server's audit log for updating the auto moderation rule.
    # @yieldparam builder [Action::Builder] An optional builder for auto moderation actions. Overrides the `actions:` argument.
    # @return [nil]
    def modify(
      name: :undef, trigger: :undef, event_type: :undef, actions: :undef,
      enabled: :undef, exempt_roles: :undef, exempt_channels: :undef,
      reason: nil
    )
      data = {
        name: name,
        enabled: enabled,
        trigger_metadata: trigger == :undef ? trigger : trigger.to_h,
        event_type: event_type == :undef ? event_type : EVENT_TYPES[event_type] || event_type,
        actions: actions == :undef ? actions : actions.to_a.map(&:to_h),
        exempt_roles: exempt_roles == :undef ? exempt_roles : exempt_roles.map(&:resolve_id),
        exempt_channels: exempt_channels == :undef ? exempt_channels : exempt_channels.map(&:resolve_id)
      }

      if block_given?
        yield((builder = Actions::Builder.new))
        data[:actions] = builder.to_a
      end

      update_data(JSON.parse(API::Server.update_automod_rule(@bot.token, @server.id, @id, **data, reason:)))
      nil
    end

    # Delete the auto moderation rule. This action cannot be reversed.
    # @param reason [String, nil] The reason to show in the audit log for deleting the auto moderation rule.
    # @return [nil]
    def delete(reason: nil)
      API::Server.delete_automod_rule(@bot.token, @server.id, @id, reason: reason)
      @server.delete_automod_rule(@id)
      nil
    end

    # Check if a specific entity is exempt from the auto moderation rule.
    # @param other [Member, Role, Channel] The entity that you want to check.
    # @return [true, false] Whether or not the entity is exempt from the auto moderation rule.
    def exempt?(other)
      case other
      when Discordrb::Member
        other.permission?(:manage_server) || other.roles.intersect?(@exempt_roles)
      when Role, Channel
        @exempt_roles.any?(other.id) || @exempt_channels.any?(other.id)
      else
        raise ArgumentError, "Unsupported type: #{other.class}"
      end
    end

    # @!visibility private
    def update_data(new_data)
      @name = new_data['name']
      @enabled = new_data['enabled']
      @event_type = new_data['event_type']
      @exempt_roles = new_data['exempt_roles'].map(&:to_i)
      @exempt_channels = new_data['exempt_channels'].map(&:to_i)
      new_data['trigger_metadata']['type'] = new_data['trigger_type']
      @trigger = Trigger.new(new_data['trigger_metadata'], self, @bot)
      @actions = new_data['actions'].map { |action| Action.new(action, @bot) }
    end

    # Metadata about how an auto moderation rule can be triggered.
    class Trigger
      # Mapping of trigger types.
      TYPES = {
        keyword: 1,
        harmful_link: 2,
        spam: 3,
        keyword_preset: 4,
        mention_spam: 5,
        member_profile: 6
      }.freeze

      # Mapping of preset types.
      PRESET_TYPES = {
        profanity: 1,
        sexual_content: 2,
        slurs: 3
      }.freeze

      # @return [Integer] the type of the trigger.
      attr_reader :type

      # @return [Integer] the max number of unique mentions allowed per message.
      attr_reader :mention_limit

      # @return [Array<String>] the substrings which will be scanned for in content.
      attr_reader :keyword_filter

      # @return [Array<String>] the regular expression patterns to match against in content.
      attr_reader :regex_patterns

      # @return [Array<String>] the substrings which should not trigger the auto moderation rule.
      attr_reader :exempt_keywords

      # @return [Array<Integer>] the internal pre-defined set of keyword to match against in content.
      attr_reader :keyword_presets

      # @return [true, false] whether or not to automatically detect when a mention raid is occuring.
      attr_reader :mention_raid_protection
      alias_method :mention_raid_protection?, :mention_raid_protection

      # @!visibility private
      def initialize(data, rule, bot)
        @bot = bot
        @rule = rule
        @type = data['type']
        @mention_limit = data['mention_total_limit'] || 0
        @keyword_filter = data['keyword_filter'] || []
        @regex_patterns = data['regex_patterns'] || []
        @exempt_keywords = data['allow_list'] || []
        @keyword_presets = data['presets'] || []
        @mention_raid_protection = data['mention_raid_protection_enabled'] || false
      end

      # Modify the attributes of the auto moderation trigger.
      # @param mention_limit [Integer] The new max amount of role and user mentions allowed per message (max of 50).
      # @param keyword_filter [Array<String>] The new substrings which will be searched for in content (max of 1000).
      # @param regex_patterns [Array<String>] The new regular expression patterns to match against in content (max of 10).
      # @param exempt_keywords [Array<String>] The new substrings which should not trigger the auto moderation rule (max of 100 or 1000).
      # @param keyword_presets [Array<Integer, Symbol>] The new internally pre-defined set of keyword to match against in content.
      # @param mention_raid_protection [true, false] Whether or not to automatically detect when a mention raid is occuring.
      # @param reason [String, nil] The reason to show in the server's audit log for modifying the auto moderation rule's trigger.
      # @return [nil]
      def modify(
        mention_limit: :undef, keyword_filter: :undef, regex_patterns: :undef, exempt_keywords: :undef,
        keyword_presets: :undef, mention_raid_protection: :undef, reason: nil
      )
        data = {
          mention_total_limit: mention_limit == :undef ? @mention_limit : mention_limit,
          keyword_filter: keyword_filter == :undef ? @keyword_filter : keyword_filter,
          regex_patterns: regex_patterns == :undef ? @regex_patterns : regex_patterns,
          allow_list: exempt_keywords == :undef ? @exempt_keywords : exempt_keywords,
          presets: keyword_presets == :undef ? @keyword_presets : keyword_presets.map { |set| PRESET_TYPES[set] || set },
          mention_raid_protection_enabled: mention_raid_protection == :undef ? @mention_raid_protection : mention_raid_protection
        }

        @rule.modify(trigger: data, reason: reason)
      end

      # @!method keyword?
      #   @return [true, false] whether or not the auto moderation rule can be triggered due to a user defined keyword.
      # @!method harmful_link?
      #   @return [true, false] whether or not the auto moderation rule can be triggered when a harmful link is posted.
      # @!method spam?
      #   @return [true, false] whether or not the auto moderation rule can be triggered due to spam content.
      # @!method keyword_preset?
      #   @return [true, false] whether or not the auto moderation rule can be triggered due to a pre-defined keyword preset.
      # @!method mention_spam?
      #   @return [true, false] whether or not the auto moderation rule can be triggered due to mention spam.
      # @!method member_profile?
      #   @return [true, false] whether or not the auto moderation rule can be triggered due to content in a member's profile.
      TYPES.each do |name, value|
        define_method("#{name}?") do
          @type == value
        end
      end
    end

    # An action that will execute whenever an automod rule is triggered.
    class Action
      # Mapping of action types.
      TYPES = {
        block_message: 1,
        send_alert_message: 2,
        timeout_member: 3,
        block_member_interaction: 4
      }.freeze

      # @return [Integer] the type of the action.
      attr_reader :type

      # @return [String, nil] the message shown to members when their message is blocked.
      attr_reader :custom_message

      # @return [Integer, nil] The ID of the channel where user content should be logged.
      attr_reader :alert_channel_id

      # @return [Integer, nil] the amount of time in seconds the user will be timed-out for.
      attr_reader :timeout_duration

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @type = data['type']
        @custom_message = data['metadata']['custom_message']
        @alert_channel_id = data['metadata']['channel_id']&.to_i
        @timeout_duration = data['metadata']['duration_seconds']
      end

      # Get the channel where user content will be logged.
      # @return [Channel, nil] The channel where user content will be logged.
      def alert_channel
        @bot.channel(@alert_channel_id) if @alert_channel_id
      end

      # @!method block_message?
      #   @return [true, false] whether or not this action will block a message.
      # @!method send_alert_message?
      #   @return [true, false] whether or not this action will send an alert message.
      # @!method timeout_member?
      #   @return [true, false] whether or not the action will timeout a server member.
      # @!method block_member_interaction?
      #   @return [true, false] whether or not the action will block a member from interacting in a server.
      TYPES.each do |name, value|
        define_method("#{name}?") do
          @type == value
        end
      end

      # @!visibility private
      def to_h
        {
          type: @type,
          metadata: {
            custom_message: @custom_message,
            channel_id: @alert_channel_id,
            duration_seconds: @timeout_duration
          }.compact
        }
      end

      # Builder for actions.
      class Builder
        # @!visibility private
        def initialize
          @actions = []
        end

        # Add an action to the builder.
        # @param type [Integer, String, Symbol] The type of the action to create. See {Action::TYPES}.
        # @param alert_channel [Integer, String, Channel, nil] The channel to which user content should be logged.
        # @param timeout_duration [Integer, nil] The duration of the timeout in seconds.
        # @param custom_message [String, nil] The additional explanation that will be shown to members when their message is blocked.
        # @note Certain types require certain arguments to be passed. To learn which types require which arguments to be passed, please refer to:
        #   https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-action-object
        def action(type, alert_channel: nil, timeout_duration: nil, custom_message: nil)
          metadata = { channel_id: alert_channel&.resolve_id, duration_seconds: timeout_duration, custom_message: custom_message }.compact

          @actions << { type: type.is_a?(Numeric) ? type : Action::TYPES[type.to_sym], metadata: metadata.empty? ? nil : metadata }.compact
        end

        alias_method :add_action, :action

        # @!visibility private
        def to_a
          @actions.uniq { |action| action[:type] }
        end
      end
    end
  end
end
