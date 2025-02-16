# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/guild-template
    module GuildTemplateEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/guild-template#get-guild-template
      # @param template_code [String] A code that creates a guild based on another guild.
      # @return [Hash<Symbol, Object>]
      def get_guild_template(template_code, **params)
        request Route[:GET, "/guilds/templates/#{template_code}"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild-template#create-guild-from-guild-template
      # @param template_code [String] A code that creates a guild based on another guild.
      # @param icon [String, #read] A base64 encoded string with the image data.
      # @return [Hash<Symbol, Object>]
      def create_guild_from_template(template_code, icon: :undef, **rest)
        request Route[:POST, "/guilds/templates/#{template_code}"],
                body: filter_undef({ icon: icon, **rest })
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild-template#get-guild-templates
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_templates(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/templates", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild-template#create-guild-template
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param name [String] 1-100 character name.
      # @param description [String]  0-120 character description.
      # @return [Hash<Symbol, Object>]
      def create_guild_template(guild_id, name:, description: :undef, **rest)
        request Route[:POST, "/guilds/#{guild_id}/templates", guild_id],
                body: filter_undef({ name: name, description: description, **rest })
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild-template#sync-guild-template
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param template_code [String] A code that creates a guild based on another guild.
      # @return [Hash<Symbol, Object>]
      def sync_guild_template(guild_id, template_code)
        request Route[:PUT, "/guilds/#{guild_id}/templates/#{template_code}"],
                body: ''
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild-template#modify-guild-template
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param template_code [String] A code that creates a guild based on another guild.
      # @param name [String] 1-100 character name.
      # @param description [String] 0-120 character description.
      # @return [Hash<Symbol, Object>].
      def modify_guild_template(guild_id, template_code, name: :undef, description: :undef, **rest)
        request Route[:PATCH, "/guilds/#{guild_id}/templates/#{template_code}"],
                body: filter_undef({ name: name, description: description, **rest })
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild-template#delete-guild-template
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param template_code [String] A code that creates a guild based on another guild.
      # @return [Hash<Symbol, Object>]
      def delete_guild_template(guild_id, template_code)
        request Route[:DELETE, "/guilds/#{guild_id}/templates/#{template_code}"]
      end
    end
  end
end
