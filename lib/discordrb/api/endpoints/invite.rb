# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/invite
    module InviteEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/invite#get-invite
      # @param invite_code [String] A code used to add a user to a guild.
      # @param with_counts [Boolean] Whether this invite should contain an approximate member count.
      # @param with_expiration [Boolean] Whether this invite should contain its expiration date.
      # @param guild_scheduled_event_id [Boolean] The ID of the scheduled event to include with this invite.
      # @return [Hash<Symbol, Object>]
      def get_invite(invite_code, with_counts: :undef, with_expiration: :undef, guild_scheduled_event_id: :undef, **_params)
        data = {
          with_counts: with_counts,
          with_expiration: with_expiration,
          guild_scheduled_event_id: guild_scheduled_event_id,
          **rest
        }

        request Route[:GET, "/invites/#{invite_code}"],
                params: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/resources/invite#delete-invite
      # @param invite_code [String] A code used to add a user to a guild.
      # @param reason [String] The reason for deleting this invite code.
      # @return [Hash<Symbol, Object>]
      def delete_invite(invite_code, reason: :undef)
        request Route[:DELETE, "/invites/#{invite_code}"],
                reason: reason
      end
    end
  end
end
