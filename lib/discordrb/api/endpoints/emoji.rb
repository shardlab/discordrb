# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/emoji
    module EmojiEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/emoji#list-guild-emojis
      # @return [Array<Hash<Symbol, Object>>]
      def list_guild_emojis(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/emojis", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/emoji#get-guild-emoji
      # @return [Hash<Symbol, Object>]
      def get_guild_emoji(guild_id, emoji_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/emojis/#{emoji_id}", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/emoji#create-guild-emoji
      # @return [Hash<Symbol, Object>]
      def create_guild_emoji(guild_id, name:, image:, roles: :undef, reason: :undef, **rest)
        data = {
          name: name,
          image: image,
          roles: roles,
          **rest
        }

        request Route[:POST, "/guilds/#{guild_id}/emojis"],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/emoji#modify-guild-emoji
      # @return [Hash<Symbol, Object>]
      def modify_guild_emoji(guild_id, emoji_id, name: :undef, roles: :undef, reason: :undef, **rest)
        data = {
          name: name,
          roles: roles,
          **rest
        }

        request Route[:PATCH, "/guilds/#{guild_id}/emojis/#{emoji_id}"],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/emoji#delete-guild-emoji
      # @return [nil]
      def delete_guild_emoji(guild_id, emoji_id, reason: :undef)
        request Route[:DELETE, "/guilds/#{guild_id}/emojis/#{emoji_id}"],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/emoji#list-application-emojis
      # @return [Array<Hash<Symbol, Object>>]
      def list_application_emojis(application_id, **params)
        request Route[:GET, "/applications/#{application_id}/emojis", application_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/emoji#get-application-emoji
      # @return [Hash<Symbol, Object>]
      def get_application_emoji(application_id, emoji_id, **params)
        request Route[:GET, "/applications/#{application_id}/emojis/#{emoji_id}", application_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/emoji#create-application-emoji
      # @return [Hash<Symbol, Object>]
      def create_application_emoji(application_id, name:, image:, **rest)
        data = {
          name: name,
          image: image,
          **rest
        }

        request Route[:POST, "/applications/#{application_id}/emojis"],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/resources/emoji#modify-application-emoji
      # @return [Hash<Symbol, Object>]
      def modify_application_emoji(application_id, emoji_id, name: :undef, **rest)
        data = {
          name: name,
          **rest
        }

        request Route[:PATCH, "/applications/#{application_id}/emojis/#{emoji_id}"],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/resources/emoji#delete-application-emoji
      # @return [nil]
      def delete_application_emoji(application_id, emoji_id)
        request Route[:DELETE, "/applications/#{application_id}/emojis/#{emoji_id}"],
      end
    end
  end
end