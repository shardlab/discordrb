# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/interactions/application-commands
    module ApplicationCommandEndpoints
      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#get-global-application-commands
      # @param application_id [Integer, String]
      # @return [Array<Hash<Symbol, Object>>]
      def get_global_application_commands(application_id, **params)
        request Route[:GET, "/applications/#{application_id}/commands"], params: params
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#create-global-application-command
      # @param application_id [Integer, String]
      # @param name [String] 	1-32 character name
      # @param description [String] 1-100 character description
      # @param options [Array<Hash>] the parameters for the command
      # @param default_permission [true, false, nil] whether the command is enabled by default when the app is added to a guild
      # @param type [1, 2, 3] the type of command, defaults `1` if not set.
      # @return [Hash<Symbol, Object>]
      def create_global_application_command(application_id, name:, description:, options: :undef,
                                            default_permission: :undef, type: :undef, **rest)
        data = {
          name: name,
          description: description,
          options: options,
          default_permission: default_permission,
          type: type,
          **rest
        }

        request Route[:POST, "/applications/#{application_id}/commands"],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#get-global-application-command
      # @param application_id [Integer, String]
      # @param command_id [Integer, String]
      # @return [Hash<Symbol, Object>]
      def get_global_application_command(application_id, command_id, **params)
        request Route[:GET, "/applications/#{application_id}/commands/#{command_id}"], params: params
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#edit-global-application-command
      # @param application_id [Integer, String]
      # @param command_id [Integer, String]
      # @param name [String] 	1-32 character name
      # @param description [String] 1-100 character description
      # @param options [Array<Hash>] the parameters for the command
      # @param default_permission [true, false, nil] whether the command is enabled by default when the app is added to a guild
      # @return [Hash<Symbol, Object>]
      def edit_global_application_command(application_id, command_id, name: :undef, description: :undef,
                                          options: :undef, default_permission: :undef, **rest)
        data = {
          name: name,
          description: description,
          options: options,
          default_permission: default_permission,
          **rest
        }

        request Route[:PATCH, "/applications/#{application_id}/commands/#{command_id}"],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#delete-global-application-command
      # @param application_id [Integer, String]
      # @param command_id [Integer, String]
      # @return [Hash<Symbol, Object>]
      def delete_global_application_command(application_id, command_id)
        request Route[:DELETE, "/applications/#{application_id}/commands/#{command_id}"]
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-global-application-commands
      # @param application_id [Integer, String]
      # @param commands [Array<Hash>]
      # @return [Array<Hash>]
      def bulk_overwrite_global_application_commands(application_id, commands)
        request Route[:PUT, "/applications/#{application_id}/commands"],
                body: commands
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#get-guild-application-commands
      # @param application_id [Integer, String]
      # @param guild_id [Integer, String]
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_application_commands(application_id, guild_id, **params)
        request Route[:GET, "/applications/#{application_id}/guilds/#{guild_id}/commands"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#create-guild-application-command
      # @param application_id [Integer, String]
      # @param guild_id [Integer, String]
      # @param name [String]	1-32 character name
      # @param description [String] 1-100 character description
      # @param options [Array<Hash>, nil] the parameters for the command
      # @param default_permission [true, false, nil] whether the command is enabled by default when the app is added to a guild
      # @param type [1, 2, 3] the type of command, defaults 1 if not set
      # @return [Hash]
      def create_guild_application_command(application_id, guild_id, name:, description:, options: :undef,
                                           default_permission: :undef, type: :undef, **rest)
        data = {
          name: name,
          description: description,
          options: options,
          default_permission: default_permission,
          type: type,
          **rest
        }

        request Route[:POST, "/applications/#{application_id}/guilds/#{guild_id}/commands"],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#get-guild-application-command
      # @param application_id [Integer, String]
      # @param guild_id [Integer, String]
      # @param command_id [Integer, String]
      # @return [Hash<Symbol, Object>]
      def get_guild_application_command(application_id, guild_id, command_id, **params)
        request Route[:GET, "/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}"], params: params
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#edit-guild-application-command
      # @param application_id [Integer, String]
      # @param guild_id [Integer, String]
      # @param command_id [Integer, String]
      # @param name [String] 	1-32 character name
      # @param description [String] 1-100 character description
      # @param options [Array<Hash>] the parameters for the command
      # @param default_permission [true, false, nil] whether the command is enabled by default when the app is added to a guild
      # @return [Hash<Symbol, Object>]
      def edit_guild_application_command(application_id, guild_id, command_id, name: :undef, description: :undef,
                                          options: :undef, default_permission: :undef, **rest)
        data = {
          name: name,
          description: description,
          options: options,
          default_permission: default_permission,
          **rest
        }

        request Route[:PATCH, "/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}"],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#delete-guild-application-command
      # @param application_id [Integer, String]
      # @param guild_id [Integer, String]
      # @param command_id [Integer, String]
      # @return [Hash<Symbol, Object>]
      def delete_guild_application_command(application_id, guild_id, command_id)
        request Route[:DELETE, "/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}"]
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-guild-application-commands
      # @param application_id [Integer, String]
      # @param guild_id [Integer, String]
      # @param commands [Array<Hash>]
      # @return [Array<Hash>]
      def bulk_overwrite_guild_application_commands(application_id, guild_id, commands)
        request Route[:PUT, "/applications/#{application_id}/guilds/#{guild_id}/commands"],
                body: commands
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#get-guild-application-command-permissions
      # @param application_id [Integer, String]
      # @param guild_id [Integer, String]
      # @return [Array<Hash>]
      def get_guild_application_command_permissions(application_id, guild_id, **params)
        request Route[:GET, "/applications/#{application_id}/guilds/#{guild_id}/commands/permissions"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#get-application-command-permissions
      # @param application_id [Integer, String]
      # @param guild_id [Integer, String]
      # @param command_id [Integer, String]
      # @return [Hash]
      def get_application_command_permissions(application_id, guild_id, command_id, **params)
        request Route[:GET, "/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}/permissions"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#edit-application-command-permissions
      # @param application_id [Integer, String]
      # @param guild_id [Integer, String]
      # @param command_id [Integer, String]
      # @param permissions [Array<Hash>]
      # @return [Hash]
      def edit_application_command_permissions(application_id, guild_id, command_id, permissions: [], **rest)
        request Route[:PUT, "/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}/permissions"],
                body: filter_undef({ permissions: permissions, **rest })
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#batch-edit-application-command-permissions
      # @param application_id [Integer, String]
      # @param guild_id [Integer, String]
      # @param permissions [Array<Hash>]
      def batch_edit_application_command_permissions(application_id, guild_id, permissions)
        request Route[:PUT, "/applications/#{application_id}/guilds/#{guild_id}/commands/permissions"],
                body: permissions
      end
    end
  end
end
