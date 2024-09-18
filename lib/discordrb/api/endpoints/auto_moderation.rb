# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/auto-moderation
    module AutoModerationEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/auto-moderation#list-auto-moderation-rules-for-guild
      # @return [Array<Hash<Symbol, Object>>]
      def list_auto_moderation_rules_for_guild(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/auto-moderation/rules", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/auto-moderation#get-auto-moderation-rule
      # @return [Hash<Symbol, Object>]
      def get_auto_moderation_rule(guild_id, auto_moderation_rule_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/auto-moderation/rules/#{auto_moderation_rule_id}", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/auto-moderation#create-auto-moderation-rule
      # @return [Hash<Symbol, Object>]
      def create_auto_moderation_rule(guild_id, name:, event_type:, trigger_type:, trigger_metadata: :undef, actions:, enabled: :undef,
                                      exempt_roles: :undef, exempt_channels: :undef, reason: :undef, **rest)
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
      # @return [Hash<Symbol, Object>]
      def modify_auto_moderation_rule(guild_id, auto_moderation_rule_id, name: :undef, event_type: :undef, trigger_metadata: :undef, actions: :undef,
                                      enabled: :undef, exempt_roles: :undef, exempt_channels: :undef, reason: :undef, **rest)
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
      # @return [nil]
      def delete_auto_moderation_rule(guild_id, auto_moderation_rule_id, reason: :undef)
        request Route[:DELETE, "/guilds/#{guild_id}/auto-moderation/rules/#{auto_moderation_rule_id}"],
                reason: reason
      end
    end
  end
end
