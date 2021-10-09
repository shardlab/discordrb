# frozen_string_literal: true

module Discordrb
  module API
    module AuditLogEndpoints
      def get_guild_audit_log(guild_id, user_id: :undef, action_type: :undef, before: :undef, limit: :undef, **params)
        query = {
          user_id: user_id,
          action_type: action_type,
          before: before,
          limit: limit,
          **params
        }

        request Route[:GET, "/guilds/#{guild_id}/audit-logs", guild_id],
                params: filter_undef(query)
      end
    end
  end
end
