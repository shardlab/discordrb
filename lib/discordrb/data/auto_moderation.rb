# frozen_string_literal: true

module Discordrb
  # Automod rules allow a server to set up rules that can trigger based on a criteria. These rules can
  #   take moderation actions such as timing out a user when a specific word is said. The `manage_server`
  #   permission is required to access any automod resource and receive any gateway event for automod rules.
  class AutoModRule
    include IDObject

    # Map of event types.
    EVENT_TYPES = {
      message_send: 1,
      member_update: 2
    }.freeze

    # @return [String] the name of this automod rule.
    attr_reader :name

    # @return [Server] the server this automod rule is from.
    attr_reader :server

    # @return [Integer] the event type of this automod rule.
    # @see EVENT_TYPES
    attr_reader :event_type

    # @return [Trigger] how this automod rule can be triggered.
    attr_reader :trigger

    # @return [Array<Action>] the actions that will execute when this automod rule is triggered.
    attr_reader :actions

    # @return [true, false] whether this automod rule is enabled or not.
    attr_reader :enabled
    alias_method :enabled?, :enabled

    # @return [Array<Role>] the roles that are ignored by this automod rule.
    attr_reader :exempt_roles

    # @return [Array<Channel>] the channels that are ignored by this automod rule.
    attr_reader :exempt_channels

    # @!visibility private
    def initialize(data, server, bot)
      @bot = bot
      @server = server
      @id = data['id'].to_i
      @creator_id = data['creator_id'].to_i
      from_other(data)
    end

    # @return [User] the user who was responsible for the creation of this automod rule.
    def creator
      @bot.user(@creator_id)
    end

    # Check if something is exempt from this automod rule.
    # @param other [Role, Channel, Member] The thing to check for exemption.
    # @return [true, false] Whether the provided object is exempt or not.
    def exempt?(other)
      case other
      when Discordrb::Member
        other.permission?(:manage_server) || other.roles.intersect?(@exempt_roles)
      when Role, Channel
        @exempt_roles.any?(other) || @exempt_channels.any?(other)
      else
        raise ArgumentError, "Unsupported type: #{other.class}"
      end
    end

    # @return [true, false] whether this rule can be triggered
    #   when a member sends or edits a message in the server.
    def message_send?
      @event_type == EVENT_TYPES[:message_send]
    end

    # @return [true, false] whether this rule can be triggered
    #   when a member edits their profile.
    def member_update?
      @event_type == EVENT_TYPES[:member_update]
    end

    # Set the name of this automod rule.
    # @param name [String] the new name of this automod rule.
    def name=(name)
      update_data(name: name)
    end

    # Set whether this automod rule is enabled or not.
    # @param enabled [true, false] whether this rule is enabled or not.
    def enabled=(enabled)
      update_data(enabled: enabled)
    end

    # Set the event type of this automod rule.
    # @param type [Symbol, Integer] the new event type of this automod rule.
    def event_type=(type)
      update_data(event_type: EVENT_TYPES[type] || type)
    end

    # Set the roles that are ignored by this automod rule.
    # @param exempt_roles [Array<Role, Integer, String>] the new exmpet roles.
    def exempt_roles=(exempt_roles)
      update_data(exempt_roles: exempt_roles.map(&:resolve_id))
    end

    # Set the channels that are ignored by this automod rule.
    # @param exempt_channels [Array<Channel, Integer, String>] the new exempt channels.
    def exempt_channels=(exempt_channels)
      update_data(exempt_channels: exempt_channels.map(&:resolve_id))
    end

    # Delete this automod rule.
    # @param reason [String, nil] the reason for deleting this automod rule.
    # @return [void]
    def delete(reason: nil)
      API::Server.delete_automod_rule(@bot.token, @server.id, @id, reason)
      server.delete_automod_rule(@id)
    end

    # Add one or more actions that will execute when this automod rule is triggered.
    # @note Creating a new action for an existing type will overwrite the current one.
    # @yieldparam builder [ActionBuilder] builder subclass for creating automod actions.
    # @return [void]
    def create_actions
      yield (builder = ActionBuilder.new)

      actions = @actions.to_h { |action| [action.type, action] }

      update_data(actions: actions.merge(builder.to_h).values.map(&:to_h))
    end

    alias_method :create_action, :create_actions

    # Delete one or more actions from this automod rule.
    # @param types [Array<Integer, Symbol>, Integer, Symbol] the action types to delete.
    # @return [void]
    def delete_actions(*types)
      types = [*types].map do |type|
        Action::TYPES[type] || type
      end

      actions = @actions.reject do |action|
        types.include?(action.type)
      end

      update_data(actions: actions.map(&:to_h))
    end

    alias_method :delete_action, :delete_actions

    # The default `inspect` method is overwritten to give more useful output.
    def inspect
      "<AutoModRule name=#{@name} creator_id=#{@creator_id} trigger=#{@trigger.to_h} actions=#{@actions.map(&:to_h)}>"
    end

    # @!visibility private
    def from_other(new_data)
      @name = new_data['name']
      @enabled = new_data['enabled']
      @event_type = new_data['event_type']
      @actions = new_data['actions'].map { |action| Action.new(action, @bot) }
      @exempt_roles = new_data['exempt_roles'].map { |role_id| server.role(role_id) }
      @exempt_channels = new_data['exempt_channels'].filter_map { |channel_id| @bot.channel(channel_id) }
      @trigger = Trigger.new(new_data['trigger_metadata'].merge({ 'type' => new_data['trigger_type'] }), self, @bot)
    end

    # @!visibility private
    def update_data(new_data)
      from_other(JSON.parse(API::Server.update_automod_rule(@bot.token, @server.id, @id,
                                                            new_data[:name], new_data[:event_type],
                                                            new_data[:trigger], new_data[:actions],
                                                            new_data[:enabled], new_data[:exempt_roles],
                                                            new_data[:exempt_channels], new_data[:reason])))
    end

    # Information used to determine when an automod rule should be triggered.
    class Trigger
      # Map of trigger types.
      TYPES = {
        keyword: 1,
        harmful_link: 2,
        spam: 3,
        keyword_preset: 4,
        mention_spam: 5,
        member_profile: 6
      }.freeze

      # Map of keyword preset types.
      PRESET_TYPES = {
        profanity: 1,
        sexual_content: 2,
        slurs: 3
      }.freeze

      # @return [Integer] the type of the automod rule's trigger.
      # @see TYPES
      attr_reader :type

      # @return [Array<String>] substrings that can trigger the automod rule.
      attr_reader :keyword_filter

      # @return [Array<String>] regex patterns that when matched can trigger the automod rule.
      # @note the regex patterns will be rust-flavoured. Each regex pattern must be 260 characters or less.
      attr_reader :regex_patterns

      # @return [Array<Integer>] set of word types that can trigger the automod rule.
      # @see PRESET_TYPES
      attr_reader :keyword_presets

      # @return [Array<String>] substrings that should not trigger the automod rule.
      attr_reader :exempt_keywords

      # @return [Integer] total number of unique role and user mentions allowed per message.
      attr_reader :total_mention_limit

      # @return [true, false] whether the automod rule will automatically detect mention raids.
      attr_reader :mention_raid_protection
      alias_method :mention_raid_protection?, :mention_raid_protection

      # @!visibility private
      def initialize(data, rule, bot)
        @bot = bot
        @rule = rule
        @type = data['type']
        @keyword_filter = data['keyword_filter'] || []
        @regex_patterns = data['regex_patterns'] || []
        @keyword_presets = data['presets'] || []
        @exempt_keywords = data['allow_list'] || []
        @total_mention_limit = data['mention_total_limit'] || 0
        @mention_raid_protection = data['mention_raid_protection_enabled'] || false
      end

      # Set the substrings that should not trigger the automod rule.
      # @param exempt_keywords [Array<String>]
      def exempt_keywords=(exempt_keywords)
        validate_trigger(field: :exempt_keywords)

        @rule.update_data(trigger: to_h.merge({ allow_list: exempt_keywords }))
      end

      # Set the regex patterns that can trigger the automod rule.
      # @param regex_patterns [Array<String>]
      def regex_patterns=(regex_patterns)
        validate_trigger(field: :regex_patterns)

        @rule.update_data(trigger: to_h.merge({ regex_patterns: regex_patterns }))
      end

      # Set the substrings that can trigger the automod rule.
      # @param keyword_filter [Array<String>]
      def keyword_filter=(keyword_filter)
        validate_trigger(field: :keyword_filter)

        @rule.update_data(trigger: to_h.merge({ keyword_filter: keyword_filter }))
      end

      # Set the maximum amount of unique mentions allowed for the rule.
      # @param mention_limit [Integer]
      def total_mention_limit=(mention_limit)
        validate_trigger(field: :total_mention_limit)

        @rule.update_data(trigger: to_h.merge({ mention_total_limit: mention_limit }))
      end

      # Set whether mention raid protection is enabled for the rule or not.
      # @param raid_protection [true, false]
      def mention_raid_protection=(raid_protection)
        validate_trigger(field: :mention_raid_protection)

        @rule.update_data(trigger: to_h.merge({ mention_raid_protection_enabled: raid_protection }))
      end

      # Set the keyword presets for this rule.
      # @param presets [Array<Integer, Symbol>]
      def keyword_presets=(presets)
        validate_trigger(field: :keyword_presets)

        presets.map! { |type| PRESET_TYPES[type] || type }

        @rule.update_data(trigger: to_h.merge({ presets: presets }))
      end

      # @!method keyword?
      #   @return [true, false] If this rule can be triggered due to a user defined keyword.
      # @!method harmful_link?
      #   @return [true, false] If this rule can be triggered when a harmful link is posted.
      # @!method spam?
      #   @return [true, false] If this rule can be triggered due to spam content.
      # @!method keyword_preset?
      #   @return [true, false] If this rule can be triggered due to a pre-defined keyword preset.
      # @!method mention_spam?
      #   @return [true, false] If this rule can be triggered due to mention spam.
      # @!method member_profile?
      #   @return [true, false] If this rule can be triggered due to content in a member's profile.
      TYPES.each do |name, value|
        define_method("#{name}?") do
          @type == value
        end
      end

      # @!visibility private
      def validate_trigger(field:)
        value = case field
                when :total_mention_limit, :mention_raid_protection
                  mention_spam?
                when :keyword_presets
                  keyword_preset?
                when :keyword_filter, :regex_patterns
                  keyword? || member_profile?
                when :exempt_keywords
                  keyword? || keyword_preset? || member_profile?
                end

        raise "Cannot set #{field} for trigger type #{TYPES.key(@type)}" unless value
      end

      # @!visibility private
      def to_h
        {
          keyword_filter: @keyword_filter,
          regex_patterns: @regex_patterns,
          presets: @keyword_presets,
          allow_list: @exempt_keywords,
          mention_total_limit: @total_mention_limit,
          mention_raid_protection_enabled: @mention_raid_protection
        }
      end
    end

    # An action that will execute whenever an automod rule is triggered.
    class Action
      # Map of action types.
      TYPES = {
        block_message: 1,
        send_alert_message: 2,
        timeout_member: 3,
        block_member_interaction: 4
      }.freeze

      # @return [Integer] the type of the action that will execute.
      # @see TYPES
      attr_reader :type

      # @return [String, nil] the explanation shown to members whenever their message is blocked.
      # @note Only returns a non-nil value when the action type is `block_message`.
      attr_reader :custom_message

      # @return [Integer, nil] The ID of the channel to which user content should be logged.
      # @note Only returns a non-nil value when the action type is `send_alert_message`.
      attr_reader :alert_channel_id

      # @return [Integer, nil] the timeout duration in seconds for this action.
      # @note Only returns a non-nil value when the action type is `timeout`.
      attr_reader :timeout_duration

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @type = data['type']
        @custom_message = data['metadata']['custom_message']
        @alert_channel_id = data['metadata']['channel_id']&.to_i
        @timeout_duration = data['metadata']['duration_seconds']
      end

      # @return [Channel, nil] The channel to which user content should be logged.
      # @note Only returns a non-nil value when the action type is `send_alert_message`.
      def alert_channel
        @bot.channel(@alert_channel_id) if @alert_channel_id
      end

      # @!method block_message?
      #   @return [true, false] whether this action will block a message.
      # @!method send_alert_message?
      #   @return [true, false] whether this action will send an alert message.
      # @!method timeout_member?
      #   @return [true, false] whether the action will timeout a server member.
      # @!method block_member_interaction?
      #   @return [true, false] whether the action will block a member from interacting in a server.
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
    end

    # Builder for automod actions.
    class ActionBuilder
      # @!visibility private
      def initialize
        @actions = []
      end

      # Add an action to the builder.
      # @param type [Integer, String, Symbol] the type of the action to create. See {Action::TYPES}.
      # @param alert_channel [Integer, String, Channel, nil] the channel to which user content should be logged.
      # @param timeout_duration [Integer, nil] the duration of the timeout in seconds.
      # @param custom_message [String, nil] the additional explanation that will be shown to members when their message is blocked.
      # @note Certain types require certain arguments to be passed. To learn which types require which arguments to be passed, please refer to:
      #   https://discord.com/developers/docs/resources/auto-moderation#auto-moderation-action-object
      # @return [void]
      def action(type, alert_channel: nil, timeout_duration: nil, custom_message: nil)
        metadata = { channel_id: alert_channel&.resolve_id, duration_seconds: timeout_duration, custom_message: custom_message }.compact

        @actions << { type: type.is_a?(Numeric) ? type : Action::TYPES[type.to_sym], metadata: metadata.empty? ? nil : metadata }.compact
      end

      # @!visibility private
      # @return [Array<Hash>]
      def to_a
        to_h.values
      end

      # @!visibility private
      # @return [Hash<Integer => Hash>]
      def to_h
        @actions.to_h { |action| [action[:type], action] }
      end
    end
  end
end
