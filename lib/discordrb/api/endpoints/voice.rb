# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/voice
    module VoiceEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/voice#list-voice-regions
      # @return [Array<Hash<Symbol, Object>>]
      def list_voice_regions(**params)
        request Route[:GET, '/voice/regions'],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/voice#get-current-user-voice-state
      # @return [Array<Hash<Symbol, Object>>]
      def get_current_user_voice_state(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/voice-states/@me"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/voice#get-user-voice-state
      # @return [Array<Hash<Symbol, Object>>]
      def get_user_voice_state(guild_id, user_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/voice-states/#{user_id}"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/voice#modify-current-user-voice-state
      # @return [nil]
      def modify_current_user_voice_state(guild_id, channel_id: :undef, suppress: :undef,
                                          request_to_speak_timestamp: :undef, **rest)
        data = {
          channel_id: channel_id,
          suppress: suppress,
          request_to_speak_timestamp: request_to_speak_timestamp,
          **rest
        }

        request Route[:PATCH, "/guilds/#{guild_id}/voice-states/@me", guild_id],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/resources/voice#modify-user-voice-state
      # @return [nil]
      def modify_user_voice_state(guild_id, user_id, channel_id: :undef, suppress: :undef, **rest)
        data = {
          channel_id: channel_id,
          suppress: suppress,
          **rest
        }

        request Route[:PATCH, "/guilds/#{guild_id}/voice-states/#{user_id}", guild_id],
                body: filter_undef(data)
      end
    end
  end
end
