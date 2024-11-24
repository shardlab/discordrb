# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/interactions/receiving-and-responding#interactions
    module InteractionEndpoints
      # @!discord_api https://discord.com/developers/docs/interactions/slash-commands#create-interaction-response
      # @param id [Integer, String] An ID that uniquely identifies an interaction.
      # @param token [String] A token to enable a response to an interaction.
      # @param type [Integer] Type of interaction.
      # @param content [String] Message content.
      # @param tts [Boolean] Whether the response is TTS.
      # @param embeds [Array<Hash>] Embed objects to include.
      # @param allowed_mentions [Hash] Allowed mentions object.
      # @param flags [Integer] Bitfield value of message flags.
      # @param components [Array<Hash>] Array of component objects.
      # @param poll [Hash] A poll request object.
      # @return [Hash]
      def create_interaction_response(id, token, type:, content: :undef, tts: :undef, embeds: :undef,
                                      custom_id: :undef, title: :undef, allowed_mentions: :undef, flags: :undef,
                                      components: :undef, poll: :undef, **rest)
        body = {
          type: type, content: content, tts: tts, embeds: embeds, allowed_mentions: allowed_mentions,
          custom_id: custom_id, title: title, flags: flags, components: components, poll: poll, **rest
        }

        request Route[:POST, "/interactions/#{id}/#{token}/callback"],
                body: filter_undef(body)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/slash-commands#get-original-interaction-response
      # @param id [Integer, String] An ID that uniquely identifies an application.
      # @param token [String] A token to enable a response to an interaction.
      # @return [Hash]
      def get_original_interaction_response(id, token)
        get_webhook_message(id, token, '@original')
      end

      # @!discord_api https://discord.com/developers/docs/interactions/slash-commands#edit-original-interaction-response
      # @param id [Integer, String] An ID that uniquely identifies an application.
      # @param token [String] A token to enable a response to an interaction.
      # @param content [String] Message content.
      # @param embeds [Array<Hash>] Embed objects to include.
      # @param allowed_mentions [Hash] Allowed mentions object.
      # @param flags [Integer] Bitfield value of message flags.
      # @param components [Array<Hash>] Array of component objects.
      # @param poll [Hash<Object>] A poll request object.
      # @return [Hash]
      def edit_original_interaction_response(id, token, type: :undef, content: :undef, embeds: :undef, allowed_mentions: :undef,
                                             flags: :undef, components: :undef, poll: :undef, **rest)
        body = {
          type: type, content: content, embeds: embeds, allowed_mentions: allowed_mentions,
          flags: flags, components: components, poll: poll, **rest
        }

        edit_webhook_message(id, token, '@original', **body)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/slash-commands#delete-original-interaction-response
      # @param id [Integer, String] An ID that uniquely identifies an application.
      # @param token [String] A token to enable a response to an interaction.
      # @return [nil]
      def delete_original_interaction_response(id, token)
        delete_webhook_message(id, token, '@original')
      end

      # @!discord_api https://discord.com/developers/docs/interactions/receiving-and-responding#create-followup-message
      # @param id [Integer, String] An ID that uniquely identifies an application.
      # @param token [String] A token to enable a response to an interaction.
      # @param content [String] Message content.
      # @param tts [Boolean] Whether the response is TTS.
      # @param embeds [Array<Hash>] Embed objects to include.
      # @param allowed_mentions [Hash] Allowed mentions object.
      # @param components [Array<Hash>] Array of component objects.
      # @param flags [Integer] Bitfield value of message flags.
      # @param applied_tags [Array<Integer, String>] Array of ID tags to apply to a forum.
      # @param poll [Hash<Object>] A poll request object.
      # @return [Hash]
      def create_followup_message(id, token, content: :undef, tts: :undef, embeds: :undef, allowed_mentions: :undef,
                                  components: :undef, flags: :undef, applied_tags: :undef, poll: :undef, **rest)
        body = {
          wait: true, content: content, tts: tts, embeds: embeds, allowed_mentions: allowed_mentions,
          flags: flags, components: components, applied_tags: applied_tags, poll: poll, **rest
        }

        execute_webhook(id, token, **body)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/receiving-and-responding#get-followup-message
      # @param id [Integer, String] An ID that uniquely identifies an application.
      # @param token [String] A token to enable a response to an interaction.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @return [Hash]
      def get_followup_message(id, token, message_id)
        get_webhook_message(id, token, message_id)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/receiving-and-responding#edit-followup-message
      # @param id [Integer, String] An ID that uniquely identifies an application.
      # @param token [String] A token to enable a response to an interaction.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @param content [String] Message content.
      # @param embeds [Array<Hash>] Embed objects to include.
      # @param allowed_mentions [Hash] Allowed mentions object.
      # @param components [Array<Hash>] Array of component objects.
      # @param poll [Hash<Object>] A poll request object.
      # @return [Hash]
      def edit_followup_message(id, token, message_id, content: :undef, embeds: :undef, allowed_mentions: :undef,
                                components: :undef, poll: :undef, **rest)
        body = {
          content: content, embeds: embeds, allowed_mentions: allowed_mentions,
          components: components, poll: poll, **rest
        }

        edit_webhook_message(id, token, message_id, **body)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/receiving-and-responding#delete-followup-message
      # @param id [Integer, String] An ID that uniquely identifies an application.
      # @param token [String] A token to enable a response to an interaction.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @return [nil]
      def delete_followup_message(id, token, message_id)
        delete_webhook_message(id, token, message_id)
      end
    end
  end
end
