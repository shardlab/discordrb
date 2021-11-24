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
    end
  end
end
