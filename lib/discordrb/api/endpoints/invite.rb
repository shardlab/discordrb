# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/invite
    module InviteEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/invite#get-invite
      # @return [Hash<Symbol, Object>]
      def get_invite(invite_code, **params)
        request Route[:GET, "/invites/#{invite_code}"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/invite#delete-invite
      # @return [Hash<Symbol, Object>]
      def delete_invite(invite_code, reason: :undef)
        request Route[:DELETE, "/invites/#{invite_code}"],
                reason: reason
      end
    end
  end
end
