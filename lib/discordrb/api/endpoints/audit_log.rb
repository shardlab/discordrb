# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/audit-log
    module AuditLogEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/audit-log#get-guild-audit-log
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param user_id [Integer, String] Entries from a specifc user.
      # @param action_type [Integer] Entries for a specific type of audit log action.
      # @param before [Integer, String] Entries with an ID less than a specific audit log entry ID.
      # @param after [Integer, String] Entries with an ID greater than a specific audit log entry ID.
      # @param limit [Integer] Maximum number of entries to return; default is 50.
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_audit_log(guild_id, user_id: :undef, action_type: :undef, before: :undef, limit: :undef, after: :undef, **params)
        query = {
          user_id: user_id,
          action_type: action_type,
          before: before,
          limit: limit,
          after: after,
          **params
        }

        request Route[:GET, "/guilds/#{guild_id}/audit-logs", guild_id],
                params: filter_undef(query)
      end
    end
  end
end
