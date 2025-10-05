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
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param name [String] 1-32 character name.
      # @param description [String] 1-100 character description.
      # @param options [Array<Hash>] The parameters for the command.
      # @param default_member_permissions [Integer] The bitwise permissions needed to use this command.
      # @param type [Integer] The type of command, defaults `1` if not set.
      # @param contexts [Integer] The contexts in which this command can be used.
      # @param integration_types [Integer] Supported installation contexts.
      # @param nsfw [Boolean] Whether this command should be age-restricted.
      # @param name_localizations [Hash] Localized name of the application command.
      # @param description_localizations [Hash] Localized description of the application command.
      # @return [Hash<Symbol, Object>]
      def create_global_application_command(application_id, name:, description:, options: :undef,
                                            default_member_permissions: :undef, type: :undef, contexts: :undef,
                                            integration_types: :undef, nsfw: :undef, name_localizations: :undef,
                                            description_localizations: :undef, **rest)
        data = {
          name: name,
          description: description,
          options: options,
          default_member_permissions: default_member_permissions,
          type: type,
          contexts: contexts,
          integration_types: integration_types,
          nsfw: nsfw,
          name_localizations: name_localizations,
          description_localizations: description_localizations,
          **rest
        }

        request Route[:POST, "/applications/#{application_id}/commands"],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#get-global-application-command
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param command_id [Integer, String] An ID that uniquely identifies an application command.
      # @return [Hash<Symbol, Object>]
      def get_global_application_command(application_id, command_id, **params)
        request Route[:GET, "/applications/#{application_id}/commands/#{command_id}"], params: params
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#edit-global-application-command
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param command_id [Integer, String] An ID that uniquely identifies an application command.
      # @param name [String] 1-32 character name.
      # @param description [String] 1-100 character description.
      # @param options [Array<Hash>] The parameters for the command.
      # @param default_member_permissions [Integer] The bitwise permissions needed to use this command.
      # @param contexts [Integer] The contexts in which this command can be used.
      # @param integration_types [Integer] Supported installation contexts.
      # @param nsfw [Boolean] Whether this command should be age-restricted.
      # @param name_localizations [Hash] Localized name of the application command.
      # @param description_localizations [Hash] Localized description of the application command.
      # @return [Hash<Symbol, Object>]
      def edit_global_application_command(application_id, command_id, name: :undef, description: :undef,
                                          options: :undef, default_member_permissions: :undef, contexts: :undef,
                                          integration_types: :undef, nsfw: :undef, name_localizations: :undef,
                                          description_localizations: :undef, **rest)
        data = {
          name: name,
          description: description,
          options: options,
          default_member_permissions: default_member_permissions,
          contexts: contexts,
          integration_types: integration_types,
          nsfw: nsfw,
          name_localizations: name_localizations,
          description_localizations: description_localizations,
          **rest
        }

        request Route[:PATCH, "/applications/#{application_id}/commands/#{command_id}"],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#delete-global-application-command
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param command_id [Integer, String] An ID that uniquely identifies an application command.
      # @return [Hash<Symbol, Object>]
      def delete_global_application_command(application_id, command_id)
        request Route[:DELETE, "/applications/#{application_id}/commands/#{command_id}"]
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-global-application-commands
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param commands [Array<Hash>] An array of application command objects.
      # @return [Array<Hash>]
      def bulk_overwrite_global_application_commands(application_id, commands)
        request Route[:PUT, "/applications/#{application_id}/commands"],
                body: commands
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#get-guild-application-commands
      # @param application_id [Integer, String] An ID that uniquely identifies an application command.
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_application_commands(application_id, guild_id, **params)
        request Route[:GET, "/applications/#{application_id}/guilds/#{guild_id}/commands"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#create-guild-application-command
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param name [String] 1-32 character name.
      # @param description [String] 1-100 character description.
      # @param options [Array<Hash>, nil] The parameters for the command.
      # @param default_member_permissions [Integer] The bitwise permissions needed to use this command.
      # @param type [Integer] The type of command, defaults 1 if not set.
      # @param nsfw [Boolean] Whether this command should be age-restricted.
      # @param name_localizations [Hash] Localized name of the application command.
      # @param description_localizations [Hash] Localized description of the application command.
      # @return [Hash]
      def create_guild_application_command(application_id, guild_id, name:, description:, options: :undef,
                                           default_member_permissions: :undef, type: :undef, nsfw: :undef,
                                           name_localizations: :undef, description_localizations: :undef, **rest)
        data = {
          name: name,
          description: description,
          options: options,
          default_member_permissions: default_member_permissions,
          type: type,
          nsfw: nsfw,
          name_localizations: name_localizations,
          description_localizations: description_localizations,
          **rest
        }

        request Route[:POST, "/applications/#{application_id}/guilds/#{guild_id}/commands"],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#get-guild-application-command
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param command_id [Integer, String] An ID that uniquely identifies an application command.
      # @return [Hash<Symbol, Object>]
      def get_guild_application_command(application_id, guild_id, command_id, **params)
        request Route[:GET, "/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}"], params: params
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#edit-guild-application-command
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param command_id [Integer, String] An ID that uniquely identifies an application command.
      # @param name [String] 1-32 character name.
      # @param description [String] 1-100 character description.
      # @param options [Array<Hash>] The parameters for the command.
      # @param default_member_permissions [Integer] The bitwise permissions needed to use this command.
      # @param nsfw [Boolean] Whether this command should be age-restricted.
      # @param name_localizations [Hash] Localized name of the application command.
      # @param description_localizations [Hash] Localized description of the application command.
      # @return [Hash<Symbol, Object>]
      def edit_guild_application_command(application_id, guild_id, command_id, name: :undef, description: :undef,
                                         options: :undef, default_member_permissions: :undef, nsfw: :undef,
                                         name_localizations: :undef, description_localizations: :undef, **rest)
        data = {
          name: name,
          description: description,
          options: options,
          default_member_permissions: default_member_permissions,
          nsfw: nsfw,
          name_localizations: name_localizations,
          description_localizations: description_localizations,
          **rest
        }

        request Route[:PATCH, "/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}"],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#delete-guild-application-command
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param command_id [Integer, String] An ID that uniquely identifies an application commmand.
      # @return [Hash<Symbol, Object>]
      def delete_guild_application_command(application_id, guild_id, command_id)
        request Route[:DELETE, "/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}"]
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#bulk-overwrite-guild-application-commands
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param commands [Array<Hash>] An array of application commmand objects.
      # @return [Array<Hash>]
      def bulk_overwrite_guild_application_commands(application_id, guild_id, commands)
        request Route[:PUT, "/applications/#{application_id}/guilds/#{guild_id}/commands"],
                body: commands
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#get-guild-application-command-permissions
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Array<Hash>]
      def get_guild_application_command_permissions(application_id, guild_id, **params)
        request Route[:GET, "/applications/#{application_id}/guilds/#{guild_id}/commands/permissions"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#get-application-command-permissions
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param command_id [Integer, String] An ID that uniquely identifies an application command.
      # @return [Hash]
      def get_application_command_permissions(application_id, guild_id, command_id, **params)
        request Route[:GET, "/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}/permissions"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/interactions/application-commands#edit-application-command-permissions
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param command_id [Integer, String] An ID that uniquely identifies an application command.
      # @param permissions [Array<Hash>] An array of application command permissions objects.
      # @return [Hash]
      def edit_application_command_permissions(application_id, guild_id, command_id, permissions: [], **rest)
        request Route[:PUT, "/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}/permissions"],
                body: filter_undef({ permissions: permissions, **rest })
      end
    end
  end
end
