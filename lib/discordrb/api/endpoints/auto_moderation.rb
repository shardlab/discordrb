# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/auto-moderation
    module AutoModerationEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/auto-moderation#list-auto-moderation-rules-for-guild
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Array<Hash<Symbol, Object>>]
      def list_auto_moderation_rules_for_guild(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/auto-moderation/rules", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/auto-moderation#get-auto-moderation-rule
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param auto_moderation_rule_id [Integer, String] An ID that uniquely identifies an auto-moderation rule.
      # @return [Hash<Symbol, Object>]
      def get_auto_moderation_rule(guild_id, auto_moderation_rule_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/auto-moderation/rules/#{auto_moderation_rule_id}", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/auto-moderation#create-auto-moderation-rule
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param name [String] Name of the rule.
      # @param event_type [1, 2] The context this rule applies to.
      # @param trigger_type [Integer] The type of action that can trigger this rule.
      # @param trigger_metadata [Hash] Extra data used to determine when a rule should should be triggered.
      # @param actions [Array<Hash>] The action to perform when the rule is triggered.
      # @param enabled [Boolean] Whether this rule is enabled or not.
      # @param exempt_roles [Array<Integer, String>] ID of roles that should not be affected by this rule.
      # @param exempt_channels [Array<Integer, String>] ID of channels that should not be affected by this rule.
      # @param reason [String] The reason for creating this rule.
      # @return [Hash<Symbol, Object>]
      def create_auto_moderation_rule(guild_id, name:, event_type:, trigger_type:, actions:, trigger_metadata: :undef,
                                      enabled: :undef, exempt_roles: :undef, exempt_channels: :undef, reason: :undef,
                                      **rest)
        data = {
          name: name,
          event_type: event_type,
          trigger_type: trigger_type,
          trigger_metadata: trigger_metadata,
          actions: actions,
          enabled: enabled,
          exempt_roles: exempt_roles,
          exempt_channels: exempt_channels,
          **rest
        }

        request Route[:POST, "/guilds/#{guild_id}/auto-moderation/rules"],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/auto-moderation#modify-auto-moderation-rule
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param auto_moderation_rule_id [Integer, String] An ID that uniquely identifies an auto-moderation rule.
      # @param name [String] Name of the rule.
      # @param event_type [1, 2] The context this rule applies to.
      # @param trigger_metadata [Hash] Extra data used to determine when a rule should should be triggered.
      # @param actions [Array<Hash>] The action to perform when the rule is triggered.
      # @param enabled [Boolean] Whether this rule is enabled or not.
      # @param exempt_roles [Array<Integer, String>] ID of roles that should not be affected by this rule.
      # @param exempt_channels [Array<Integer, String>] ID of channels that should not be affected by this rule.
      # @param reason [String] The reason for editing this rule.
      # @return [Hash<Symbol, Object>]
      def modify_auto_moderation_rule(guild_id, auto_moderation_rule_id, name: :undef, event_type: :undef, trigger_metadata: :undef,
                                      actions: :undef, enabled: :undef, exempt_roles: :undef, exempt_channels: :undef, reason: :undef,
                                      **rest)
        data = {
          name: name,
          event_type: event_type,
          trigger_metadata: trigger_metadata,
          actions: actions,
          enabled: enabled,
          exempt_roles: exempt_roles,
          exempt_channels: exempt_channels,
          **rest
        }

        request Route[:PATCH, "/guilds/#{guild_id}/auto-moderation/rules/#{auto_moderation_rule_id}"],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/auto-moderation#delete-auto-moderation-rule
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param auto_moderation_rule_id [Integer, String] An ID that uniquely identifies an auto-moderation rule.
      # @param reason [String] The reason for deleting this rule.
      # @return [nil]
      def delete_auto_moderation_rule(guild_id, auto_moderation_rule_id, reason: :undef)
        request Route[:DELETE, "/guilds/#{guild_id}/auto-moderation/rules/#{auto_moderation_rule_id}"],
                reason: reason
      end
    end
  end
end
