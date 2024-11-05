# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/user#users-resource
    module UserEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/user#get-current-user
      # @return [Hash<Symbol, Object>]
      def get_current_user(**params)
        request Route[:GET, '/users/@me'], params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/user#get-user
      # @param user_id [Integer, String] An ID that uniquely identifies a user.
      # @return [Hash<Symbol, Object>]
      def get_user(user_id, **params)
        request Route[:GET, "/users/#{user_id}"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/user#modify-current-user
      # @param username [String] New name of the current user. May randomize the discriminator.
      # @param avatar [String, read] A base64 encoded string with the image data.
      # @return [Hash<Symbol, Object>]
      def modify_current_user(username: :undef, avatar: :undef, **rest)
        request Route[:PATCH, '/users/@me'],
                body: filter_undef({ username: username, avatar: avatar, **rest })
      end

      # @!discord_api https://discord.com/developers/docs/resources/user#get-current-user-guilds
      # @return [Hash<Symbol, Object>]
      def get_current_user_guilds(**params)
        request Route[:GET, '/users/@me/guilds'],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/user#leave-guild
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Hash<Symbol, Object>]
      def leave_guild(guild_id)
        request Route[:DELETE, "/users/@me/guilds/#{guild_id}"]
      end

      # @!discord_api https://discord.com/developers/docs/resources/user#create-dm
      # @param recipient_id [Integer, String] The user to open a DM with.
      # @return [Hash<Symbol, Object>]
      def create_dm(recipient_id, **rest)
        request Route[:POST, '/users/@me/channels'], body: { recipient_id: recipient_id, **rest }
      end

      # @!discord_api https://discord.com/developers/docs/resources/user#get-user-connections
      # @return [Hash<Symbol, Object>]
      def get_current_user_connections(**params)
        request Route[:GET, '/users/@me/connections'], params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/user#get-current-user-application-role-connection
      # @return [Hash<Symbol, Object>]
      def get_current_user_application_role_connections(application_id, **params)
        request Route[:GET, "/users/@me/applications/#{application_id}/role-connection"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/user#update-current-user-application-role-connection
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param platform_name [String] Max 50 character name of a connected platform.
      # @param platform_username [String] Max 100 character username of a connected platform.
      # @param metadata [Hash<Symbol, Object>] Max 100 character Role connection metadata keys for a connected platform.
      # @return [Hash<Symbol, Object>]
      def update_current_user_application_role_connections(application_id, platform_name: :undef, platform_username: :undef,
                                                           metadata: :undef, **params)
        data = {
          platform_name: platform_name,
          platform_username: platform_username,
          metadata: metadata,
          **params
        }

        request Route[:PUT, "/users/@me/applications/#{application_id}/role-connection"],
                body: filter_undef(data)
      end
    end
  end
end
