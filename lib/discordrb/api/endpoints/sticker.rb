# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/sticker
    module StickerEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/sticker#get-sticker
      # @param sticker_id [String, Integer] An ID that uniquely identifies a sticker.
      # @return [Hash<Symbol, Object>]
      def get_sticker(sticker_id, **params)
        request Route[:GET, "/stickers/#{sticker_id}"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/sticker#list-nitro-sticker-packs
      # @return [Array<Hash<Symbol, Object>>]
      def list_nitro_sticker_packs(**params)
        request Route[:GET, '/sticker-packs'],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/sticker#list-guild-stickers
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Array<Hash<Symbol, Object>>]
      def list_guild_stickers(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/stickers", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/sticker#get-guild-sticker
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param sticker_id [String, Integer] An ID that uniquely identifies a sticker.
      # @return [Hash<Symbol, Object>]
      def get_guild_sticker(guild_id, sticker_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/stickers/#{sticker_id}", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/sticker#create-guild-sticker
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param name [String] Name of the sticker.
      # @param description [String] Description of the sticker.
      # @param tags [string] Autocomplete tags, max 200 characters.
      # @param file [File] PNG, APNG, GIF, or Lottie file.
      # @param reason [String] The reason the for creating sticker.
      # @return [Hash<Symbol, Object>]
      def create_guild_sticker(guild_id, name:, description:, tags:, file:, reason: :undef, **rest)
        data = {
          name: name,
          description: description,
          tags: tags,
          file: file,
          **rest
        }

        request Route[:POST, "/guilds/#{guild_id}/stickers", guild_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/sticker#modify-guild-sticker
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param sticker_id [String, Integer] An ID that uniquely identifies a sticker.
      # @param name [String] Name of the sticker.
      # @param description [String] Description of the sticker.
      # @param tags [string] Autocomplete tags, max 200 characters.
      # @param reason [String] The reason the for modifiying this sticker.
      # @return [Hash<Symbol, Object>]
      def modify_guild_sticker(guild_id, sticker_id,
                               name: :undef, description: :undef, tags: :undef, reason: :undef, **rest)
        data = filter_undef(
          {
            name: name,
            description: description,
            tags: tags,
            **rest
          }
        )

        request Route[:PATCH, "/guilds/#{guild_id}/stickers/#{sticker_id}", guild_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/sticker#delete-guild-sticker
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param sticker_id [String, Integer] An ID that uniquely identifies a sticker.
      # @return [nil]
      def delete_guild_sticker(guild_id, sticker_id, reason: :undef)
        request Route[:PATCH, "/guilds/#{guild_id}/stickers/#{sticker_id}", guild_id],
                reason: reason
      end
    end
  end
end
