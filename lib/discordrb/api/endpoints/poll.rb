# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/poll
    module PollEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/poll#get-answer-voters
      # @return [Array<Hash<Symbol, Object>>]
      def get_answer_voters(channel_id, message_id, answer_id, after: :undef, limit: :undef, **params)
        request Route[:GET, "/channels/#{channel_id}/polls/#{message_id}/answer/#{answer_id}", message_id],
                params: filter_undef({ after: after, limit: limit, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/poll#end-poll
      # @return [Array<Hash<Symbol, Object>>]
      def end_poll(channel_id, message_id, **params)
        request Route[:POST, "/channels/#{channel_id}/polls/#{message_id}/expire", message_id],
                params: params
      end
    end
  end
end
