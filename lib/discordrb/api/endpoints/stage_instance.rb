# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/stage-instance
    module StageInstanceEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/stage-instance#create-stage-instance
      # @return [Hash<Symbol, Object>]
      def create_stage_instance(channel_id:, topic:, privacy_level: :undef, reason: :undef, **rest)
        data = {
          channel_id: channel_id,
          topic: topic,
          privacy_level: privacy_level,
          **rest
        }

        request Route[:POST, '/stage-instances'],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/stage-instance#get-stage-instance
      # @return [Hash<Symbol, Object>]
      def get_stage_instance(channel_id, **params)
        request Route[:GET, "/stage-instances/#{channel_id}", channel_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/stage-instance#modify-stage-instance
      # @return [Hash<Symbol, Object>]
      def modify_stage_instance(channel_id, topic: :undef, privacy_level: :undef, reason: :undef, **rest)
        data = {
          topic: topic,
          privacy_level: privacy_level,
          **rest
        }

        request Route[:PATCH, "/stage-instances/#{channel_id}", channel_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/stage-instance#delete-stage-instance
      # @return [untyped]
      def delete_stage_instance(channel_id, reason: :undef)
        request Route[:DELETE, "/stage-instances/#{channel_id}", channel_id],
                reason: reason
      end
    end
  end
end
