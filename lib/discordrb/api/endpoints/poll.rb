# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/poll
    module PollEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/poll#get-answer-voters
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @param answer_id [Integer, String] An ID that uniquely identifies a poll answer.
      # @param after [Integer, String] Gets users after this user ID.
      # @param limit [Integer] Max number of users between 1-100 to return.
      # @return [Array<Hash<Symbol, Object>>]
      def get_answer_voters(channel_id, message_id, answer_id, after: :undef, limit: :undef, **params)
        request Route[:GET, "/channels/#{channel_id}/polls/#{message_id}/answer/#{answer_id}", channel_id],
                params: filter_undef({ after: after, limit: limit, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/poll#end-poll
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @return [Array<Hash<Symbol, Object>>]
      def end_poll(channel_id, message_id, **rest)
        request Route[:POST, "/channels/#{channel_id}/polls/#{message_id}/expire", channel_id],
                body: rest
      end
    end
  end
end
