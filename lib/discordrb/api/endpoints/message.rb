# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/message
    module MessageEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/message#get-channel-messages
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param around [Integer, String] Messages around this ID.
      # @param before [Integer, String] Messages before this ID.
      # @param after [Integer, String] Messages after this ID.
      # @param limit [Integer] 1-100 max number of messages to get.
      # @return [Array<Hash<Symbol, Object>>]
      def get_channel_messages(channel_id, around: :undef, before: :undef, after: :undef, limit: :undef, **params)
        request Route[:GET, "/channels/#{channel_id}/messages", channel_id],
                params: filter_undef({ around: around, before: before, after: after, limit: limit, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/message#get-channel-message
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @return [Hash<Symbol, Object>]
      def get_channel_message(channel_id, message_id, **params)
        request Route[:GET, "/channels/#{channel_id}/message/#{message_id}", channel_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/message#create-message
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param content [String] Message content up to 2,000 characters.
      # @param nonce [Integer] Unique number Used to verifiy if a message was sent.
      # @param tts [Boolean] Whether this is a TTS message. 
      # @param files [File] File contents being sent.
      # @param embeds [Array<Hash<Symbol, Object>>] Up to 10 embed objects to include.
      # @param allowed_mentions [Hash<Symbol, Object>] An allowed mentions object. 
      # @param message_reference [Hash<Symbol, Object>] Whether this message should be a reply or forward.
      # @param components [Array<Symbol, Object>>] Message components to include.
      # @param sticker_ids [Array] ID of up to 3 stickers.
      # @param flags [Integer] Bitfield value of message flags.
      # @param enforce_nonce [Boolean] Whether the nonce should be enforced.
      # @param poll [Hash<Symbol, Object>] A poll request object.
      # @return [Hash<Symbol, Object>]
      def create_message(channel_id,
                         content: :undef, tts: :undef, files: :undef, embeds: :undef, allowed_mentions: :undef,
                         message_reference: :undef, components: :undef, sticker_ids: :undef, flags: :undef,
                         enforce_nonce: :undef, poll: :undef, **rest)
        body = filter_undef({
                              content: content,
                              tts: tts,
                              embeds: embeds,
                              allowed_mentions: allowed_mentions,
                              message_reference: message_reference,
                              components: components,
                              sticker_ids: sticker_ids,
                              flags: flags,
                              enforce_nonce: enforce_nonce,
                              poll: poll,
                              **rest
                            })

        if files
          files = files.zip(0...files.count).map { |file, index| ["file[#{index}]", file] }.to_h
          body = { **files, payload_json: JSON.dump(body) }
        end

        request Route[:POST, "/channels/#{channel_id}/messages", channel_id],
                body: body
      end

      # @!discord_api https://discord.com/developers/docs/resources/message#crosspost-message
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @return [Hash<Symbol, Object>]
      def crosspost_message(channel_id, message_id, **rest)
        request Route[:POST, "/channels/#{channel_id}/messages/#{message_id}/crosspost", channel_id],
                body: rest
      end

      # @!discord_api https://discord.com/developers/docs/resources/message#create-reaction
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @param emoji [String] An URL encoded emoji. Custom emojis should be in the name:id format.
      # @return [nil]
      def create_reaction(channel_id, message_id, emoji)
        request Route[:PUT, "/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji}/@me", channel_id],
                body: ''
      end

      # @!discord_api https://discord.com/developers/docs/resources/message#delete-own-reaction
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @param emoji [String] An URL encoded emoji. Custom emojis should be in the name:id format.
      # @return [nil]
      def delete_own_reaction(channel_id, message_id, emoji)
        request Route[:DELETE, "/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji}/@me", channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/message#delete-user-reaction
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @param emoji [String] An URL encoded emoji. Custom emojis should be in the name:id format.
      # @param user_id [Integer, String] An ID that uniquely identifies a user.
      # @return [nil]
      def delete_user_reaction(channel_id, message_id, emoji, user_id)
        request Route[:DELETE,
                      "/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji}/#{user_id}",
                      channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/message#get-reactions
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @param emoji [String] An URL encoded emoji. Custom emojis should be in the name:id format.
      # @param after [Integer, String] Users after this user ID.
      # @param limit [Integer] 1-100 max number of users to get.
      # @param type [Integer] Type of reaction.
      # @return [Array<Hash<Symbol, Object>>]
      def get_reactions(channel_id, message_id, emoji, after: :undef, limit: :undef, type: :undef, **params)
        query = {
          after: after,
          limit: limit,
          type: type,
          **params
        }

        request Route[:GET, "/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji}", channel_id],
                params: filter_undef(query)
      end

      # @!discord_api https://discord.com/developers/docs/resources/message#delete-all-reactions
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @return [nil]
      def delete_all_reactions(channel_id, message_id)
        request Route[:DELETE, "/channels/#{channel_id}/messages/#{message_id}/reactions", channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/message#delete-all-reactions-for-emoji
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @param emoji [String] An URL encoded emoji. Custom emojis should be in the name:id format.
      # @return [nil]
      def delete_all_reactions_for_emoji(channel_id, message_id, emoji)
        request Route[:DELETE, "/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji}", channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/message#edit-message
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @param content [String] Message content up to 2,000 characters.
      # @param embeds [Array<Hash<Symbol, Object>>] Up to 10 embed objects to add.
      # @param flags [Integer] Bitfield value of message flags.
      # @param files [File] File contents being added.
      # @param allowed_mentions [Hash<Symbol, Object>] An allowed mentions object. 
      # @param components [Array<Symbol, Object>>] Message components to add.
      # @return [Hash<Symbol, Object>]
      def edit_message(channel_id,
                       message_id, content: :undef, embeds: :undef, flags: :undef, file: :undef,
                       allowed_mentions: :undef, attachments: :undef, components: :undef, **rest)
        body = filter_undef({
                              content: content,
                              tts: tts,
                              embeds: embeds,
                              allowed_mentions: allowed_mentions,
                              message_reference: message_reference,
                              components: components,
                              flags: flags,
                              **rest
                            })

        body = { file: file, payload_json: JSON.dump(body) } if file

        request Route[:PATCH, "/channels/#{channel_id}/messages/#{message_id}", channel_id],
                body: body
      end

      # @!discord_api https://discord.com/developers/docs/resources/message#delete-message
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @param reason [String] The reason for deleting this message.
      # @return [nil]
      def delete_message(channel_id, message_id, reason: :undef)
        request Route[:DELETE, "/channels/#{channel_id}/messages/#{message_id}"],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/message#bulk-delete-messages
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param message_id [Array] An array containing 2-100 message ID's to delete.
      # @param reason [String] The reason for deleting these messages.
      # @return [nil]
      def bulk_delete_messages(channel_id, messages, reason: :undef)
        request Route[:POST, "/channels/#{channel_id}/messages/bulk-delete", channel_id],
                body: messages,
                reason: reason
      end
    end
  end
end
