# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/webhook
    module WebhookEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/webhook#create-webhook
      # @param channel_id [String, Integer] An ID that uniquely identifies a channel.
      # @param name [String] 1-80 character name of the webhook to create.
      # @param avatar [String, #read] A base64 encoded string with the image data.
      # @param reason [String] The reason for creating this webhook.
      # @return [Hash<Symbol, Object>]
      def create_webhook(channel_id, name: :undef, avatar: :undef, reason: :undef, **rest)
        request Route[:POST, "/channels/#{channel_id}/webhooks", channel_id],
                body: filter_undef({ name: name, avatar: avatar, **rest }),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/webhook#get-channel-webhooks
      # @param channel_id [String, Integer] An ID that uniquely identifies a channel.
      # @return [Array<Hash<Symbol, Object>>]
      def get_channel_webhooks(channel_id, **params)
        request Route[:GET, "/channels/#{channel_id}/webhooks", channel_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/webhook#get-guild-webhooks
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_webhooks(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/webhooks", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/webhook#get-webhook
      # @param webhook_id [Integer, String] An ID that uniquely identifies a webhook.
      # @return [Hash<Symbol, Object>]
      def get_webhook(webhook_id, **params)
        request Route[:GET, "/webhooks/#{webhook_id}", webhook_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/webhook#get-webhook-with-token
      # @param webhook_id [Integer, String] An ID that uniquely identifies a webhook.
      # @param webhook_token [String] The secure token of the webhook.
      # @return [Hash<Symbol, Object>]
      def get_webhook_with_token(webhook_id, webhook_token, **params)
        request Route[:GET, "/webhooks/#{webhook_id}/#{webhook_token}", webhook_id, :get_webhooks_id_token],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/webhook#modify-webhook
      # @param webhook_id [Integer, String] An ID that uniquely identifies a webhook.
      # @param name [String] Default name of the webhook.
      # @param avatar [String, #read] A base64 encoded string with the image data.
      # @param channel_id [String, Integer] New channel ID to move this webhook to.
      # @return [Hash<Symbol, Object>]
      def modify_webhook(webhook_id, name: :undef, avatar: :undef, channel_id: :undef, **rest)
        request Route[:PATCH, "/webhooks/#{webhook_id}", webhook_id],
                body: filter_undef({ name: name, avatar: avatar, channel_id: channel_id, **rest })
      end

      # @!discord_api https://discord.com/developers/docs/resources/webhook#modify-webhook-with-token
      # @param webhook_id [Integer, String] An ID that uniquely identifies a webhook.
      # @param webhook_token [String] The secure token of the webhook.
      # @param name [String] Default name of the webhook.
      # @param avatar [String, #read] A base64 encoded string with the image data.
      # @return [Hash<Symbol, Object>]
      def modify_webhook_with_token(webhook_id, webhook_token, name: :undef, avatar: :undef, **rest)
        request Route[:PATCH, "/webhooks/#{webhook_id}/#{webhook_token}", webhook_id, :patch_webhooks_id_token],
                body: filter_undef({ name: name, avatar: avatar, channel_id: channel_id, **rest })
      end

      # @!discord_api https://discord.com/developers/docs/resources/webhook#delete-webhook
      # @param webhook_id [Integer, String] An ID that uniquely identifies a webhook.
      # @param reason [String] The reason for deleting this webhook.
      # @return [nil]
      def delete_webhook(webhook_id, reason: :undef)
        request Route[:DELETE, "/webhooks/#{webhook_id}", webhook_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/webhook#delete-webhook-with-token
      # @param webhook_id [Integer, String] An ID that uniquely identifies a webhook.
      # @param webhook_token [String] The secure token of the webhook.
      # @param reason [String] The reason for deleting this webhook.
      # @return [nil]
      def delete_webhook_with_token(webhook_id, webhook_token, reason: :undef)
        request Route[:DELETE, "/webhooks/#{webhook_id}/#{webhook_token}", webhook_id, :delete_webhook_id_token],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/webhook#execute-webhook
      # @param webhook_id [Integer, String] An ID that uniquely identifies a webhook.
      # @param webhook_token [String] The secure token of the webhook.
      # @return [nil, Hash<Symbol, Object>]
      def execute_webhook(webhook_id, webhook_token, wait: :undef, thread_id: :undef, content: :undef, username: :undef,
                          avatar_url: :undef, tts: :undef, file: :undef, flags: :undef, embeds: :undef, allowed_mentions: :undef,
                          components: :undef, applied_tags: :undef, poll: :undef, params: {}, **rest)
        data = {
          content: content,
          username: username,
          avatar_url: avatar_url,
          tts: tts,
          embeds: embeds,
          allowed_mentions: allowed_mentions,
          components: components,
          **rest
        }

        data = { file: file, payload_json: JSON.dump(filter_undef(data)) } if file && file != :undef

        request Route[:POST, "/webhooks/#{webhook_id}/#{webhook_token}"],
                params: filter_undef({ wait: wait, thread_id: thread_id, **params }),
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/resources/webhook#get-webhook-message
      # @param webhook_id [Integer, String] An ID that uniquely identifies a webhook.
      # @param webhook_token [String] The secure token of the webhook.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @return [Hash<Symbol, Object>]
      def get_webhook_message(webhook_id, webhook_token, message_id, **params)
        request Route[:GET, "/webhooks/#{webhook_id}/#{webhook_token}/messages/#{message_id}", webhook_id, :get_webhooks_id_token_messages_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/webhook#edit-webhook-message
      # @param webhook_id [Integer, String] An ID that uniquely identifies a webhook.
      # @param webhook_token [String] The secure token of the webhook.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @param content [String] Message content up to 2,000 characters.
      # @param embeds [Array<Hash>] Up to 10 embed objects to include.
      # @param file [File] File contents being sent.
      # @param allowed_mentions [Hash] An allowed mentions object. 
      # @param attachments [File] Attatched files.
      # @param components [Array<Hash>] An array of message components to include.
      # @return [Hash<Symbol, Object>]
      def edit_webhook_message(webhook_id, webhook_token, message_id, content: :undef, embeds: :undef, file: :undef,
                               allowed_mentions: :undef, attachments: :undef, components: :undef, **rest)
        data = {
          content: content,
          embeds: embeds,
          allowed_mentions: allowed_mentions,
          components: components,
          attachments: attachments,
          **rest
        }

        data = { file: file, payload_json: JSON.dump(filter_undef(data)) } if file && file != :undef

        request Route[:PATCH, "/webhooks/#{webhook_id}/#{webhook_token}/messages/#{message_id}", webhook_id, :patch_webhooks_id_token_messages_id],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/resources/webhook#delete-webhook-message
      # @param webhook_id [Integer, String] An ID that uniquely identifies a webhook.
      # @param webhook_token [String] The secure token of the webhook.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @return [nil]
      def delete_webhook_message(webhook_id, webhook_token, message_id)
        request Route[:DELETE, "/webhooks/#{webhook_id}/#{webhook_token}/messages/#{message_id}", webhook_id, :delete_webhooks_id_token_messages_id]
      end
    end
  end
end
