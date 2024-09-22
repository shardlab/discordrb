
module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/interactions/receiving-and-responding#interactions
    module InteractionEndpoints
      # @!discord_api https://discord.com/developers/docs/interactions/slash-commands#create-interaction-response
      # @param id [Integer, String]
      # @param token [String]
      # @param type [Integer]
      # @param content [String]
      # @param tts [true, false]
      # @param embeds [Array<Hash>]
      # @param allowed_mentions [Hash]
      # @param flags [Integer]
      # @param components [Array<Hash>]
      # @return [Hash]
      def create_interaction_response(id, token, type:, content: :undef, tts: :undef, embeds: :undef,
                                      allowed_mentions: :undef, flags: :undef, components: :undef, **rest)
        body = {
          type: type, content: content, tts: tts, embeds: embeds, allowed_mentions: allowed_mentions,
          flags: flags, components: components, **rest
        }

        request Route[:POST, "/interactions/#{id}/#{token}/callback"],
                body: filter_undef(body)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/slash-commands#get-original-interaction-response
      # @param id [Integer, String]
      # @param token [String]
      # @return [Hash]
      def get_original_interaction_response(id, token)
        get_webhook_message(id, token, '@original')
      end

      # @!discord_api https://discord.com/developers/docs/interactions/slash-commands#edit-original-interaction-response
      # @param id [Integer, String]
      # @param token [String]
      # @param content [String]
      # @param embeds [Array<Hash>]
      # @param allowed_mentions [Hash]
      # @param flags [Integer]
      # @param components [Array<Hash>]
      # @return [Hash]
      def edit_original_interaction_response(id, token, content: :undef, embeds: :undef, allowed_mentions: :undef,
                                             flags: :undef, components: :undef, **rest)
        body = {
          type: type, content: content, embeds: embeds, allowed_mentions: allowed_mentions,
          flags: flags, components: components, **rest
        }

        edit_webhook_message(id, token, '@original', **body)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/slash-commands#delete-original-interaction-response
      # @param id [Integer, String]
      # @param token [String]
      def delete_original_interaction_response(id, token)
        delete_webhook_message(id, token, '@original')
      end

      # @!discord_api https://discord.com/developers/docs/interactions/receiving-and-responding#create-followup-message
      # @param id [Integer, String]
      # @param token [String]
      def create_followup_message(id, token, content: :undef, tts: :undef, embeds: :undef, allowed_mentions: :undef,
                                  components: :undef, file: :undef, flags: :undef, applied_tags: :undef, poll: :undef, **rest)
        body = {
          wait: true, content: content, tts: :undef, embeds: embeds, allowed_mentions: allowed_mentions, file: :undef,
          flags: flags, components: components, applied_tags: applied_tags, poll: poll, **rest
        }

        execute_webhook(id, token, **body)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/receiving-and-responding#get-followup-message
      # @param id [Integer, String]
      # @param token [String]
      # @param message_id [Integer, String]
      def get_followup_message(id, token, message_id)
        get_webhook_message(id, token, message_id)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/receiving-and-responding#edit-followup-message
      # @param id [Integer, String]
      # @param token [String]
      # @param message_id [Integer, String]
      def edit_followup_message(id, token, message_id)
        edit_webhook_message(id, token, message_id, **body)
      end

      # @!discord_api https://discord.com/developers/docs/interactions/receiving-and-responding#delete-followup-message
      # @param id [Integer, String]
      # @param token [String]
      # @param message_id [Integer, String]
      # @return [nil]
      def delete_followup_message(id, token, message_id)
        delete_webhook_message(id, token, message_id)
      end
    end
  end
end
