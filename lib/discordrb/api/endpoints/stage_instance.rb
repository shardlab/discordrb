# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/stage-instance
    module StageInstanceEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/stage-instance#create-stage-instance
      # @param channel_id [Integer, String] An ID of a stage channel.
      # @param topic [String] 1-120 character description;
      # @param privacy_level [Integer] Who this stage instance is visible to.
      # @param send_start_notification [Boolean] Whether @everyone should be pinged when the stage instance begins.
      # @param guild_scheduled_event_id [Integer, String] A scheduled event associated with this stage instance.
      # @param reason [String] The reason for creating this stage instance.
      # @return [Hash<Symbol, Object>]
      def create_stage_instance(channel_id, topic:, privacy_level: :undef, send_start_notification: :undef,
                                guild_scheduled_event_id: :undef, reason: :undef, **rest)
        data = {
          channel_id: channel_id,
          topic: topic,
          privacy_level: privacy_level,
          send_start_notification: send_start_notification,
          guild_scheduled_event_id: guild_scheduled_event_id,
          **rest
        }

        request Route[:POST, '/stage-instances'],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/stage-instance#get-stage-instance
      # @param channel_id [Integer, String] An ID of a stage channel.
      # @return [Hash<Symbol, Object>]
      def get_stage_instance(channel_id, **params)
        request Route[:GET, "/stage-instances/#{channel_id}", channel_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/stage-instance#modify-stage-instance
      # @param channel_id [Integer, String] An ID of a stage channel.
      # @param topic [String] 1-120 character description.
      # @param privacy_level [Integer] Who this stage instance is visible to.
      # @param reason [String] The reason for modifiying this stage instance.
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
      # @param channel_id [Integer, String] An ID of a stage channel.
      # @param reason [String] The reason for deleting this stage instance.
      # @return [untyped]
      def delete_stage_instance(channel_id, reason: :undef)
        request Route[:DELETE, "/stage-instances/#{channel_id}", channel_id],
                reason: reason
      end
    end
  end
end
