# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/soundboard
    module SoundboardEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/soundboard#send-soundboard-sound
      # @param channel_id [String, Integer] An ID that uniquely identifies a channel.
      # @param sound_id [String, Integer] ID of the sound to play.
      # @param source_guild_id [String, Integer] ID of the guild the sound is from.
      # @return [nil]
      def send_soundboard_sound(channel_id, sound_id, source_guild_id: :undef, **rest)
        request Route[:POST, "/channels/#{channel_id}/send-soundboard-sound", channel_id],
                body: filter_undef({ sound_id: sound_id, source_guild_id: source_guild_id, **rest })
      end

      # @!discord_api https://discord.com/developers/docs/resources/soundboard#list-default-soundboard-sounds
      # @return [Array<Hash<Symbol, Object>>]
      def list_default_soundboard_sounds(**params)
        request Route[:GET, '/soundboard-default-sounds'],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/soundboard#list-guild-soundboard-sounds
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Array<Hash<Symbol, Object>>]
      def list_guild_soundboard_sounds(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/soundboard-sounds"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/soundboard#get-guild-soundboard-sound
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param sound_id [Integer, String] An ID that uniquely identifies a soundboard sound.
      # @return [Hash<Symbol, Object>]
      def get_guild_soundboard_sound(guild_id, sound_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/soundboard-sounds/#{sound_id}"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/soundboard#create-guild-soundboard-sound
      # @param guild_id [String, Integer] An ID that uniquely identifies a channel.
      # @param name [String] 2-32 character name of the soundboard sound.
      # @param sound [String, #read] A base64 encoded string with the sound data.
      # @param volume [Integer] 0-1 volume of the sound.
      # @param emoji_id [String, Integer] ID of the custom emoji for this sound.
      # @param emoji_name [String] Unicode character of the standard emoji for this sound.
      # @param reason [String] The reason for creating this soundboard sound.
      # @return [Hash<Symbol, Object>]
      def create_guild_soundboard_sound(guild_id, name:, sound:, volume: :undef,
                                        emoji_id: :undef, emoji_name: :undef, reason: :undef,
                                        **rest)
        data = {
          name: name,
          sound: sound,
          volume: volume,
          emoji_id: emoji_id,
          emoji_name: emoji_name,
          **rest
        }

        request Route[:POST, "/guilds/#{guild_id}/soundboard-sounds", guild_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/soundboard#modify-guild-soundboard-sound
      # @param guild_id [String, Integer] An ID that uniquely identifies a channel.
      # @param sound_id [String, Integer] An ID that uniquely identifies a soundboard sound.
      # @param name [String] 2-32 character name of the soundboard sound.
      # @param volume [Integer] 0-1 volume of the sound.
      # @param emoji_id [String, Integer] ID of the custom emoji for this sound.
      # @param emoji_name [String] Unicode character of the standard emoji for this sound.
      # @param reason [String] The reason for modifiying this soundboard sound.
      # @return [Hash<Symbol, Object>]
      def modifiy_guild_soundboard_sound(guild_id, sound_id, name: :undef, volume: :undef,
                                         emoji_id: :undef, emoji_name: :undef, reason: :undef,
                                         **rest)
        data = {
          name: name,
          volume: volume,
          emoji_id: emoji_id,
          emoji_name: emoji_name,
          **rest
        }

        request Route[:PATCH, "/guilds/#{guild_id}/soundboard-sounds/#{sound_id}", guild_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/soundboard#delete-guild-soundboard-sound
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param sound_id [Integer, String] An ID that uniquely identifies a soundboard sound.
      # @param reason [String] The reason for deleting this soundboard sound.
      # @return [Hash<Symbol, Object>]
      def delete_guild_soundboard_sound(guild_id, sound_id, reason: :undef)
        request Route[:DELETE, "/guilds/#{guild_id}/soundboard-sounds/#{sound_id}"],
                reason: reason
      end
    end
  end
end
