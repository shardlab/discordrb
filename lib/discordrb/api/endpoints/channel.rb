# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/channel
    module ChannelEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/channel#get-channel
      # @return [Hash<Symbol, Object>]
      def get_channel(channel_id, **params)
        request Route[:GET, "/channels/#{channel_id}", channel_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#modify-channel
      # @return [Hash<Symbol, Object>]
      def modify_channel(channel_id,
                         name: :undef, icon: :undef, type: :undef, position: :undef, topic: :undef,
                         nsfw: :undef, rate_limit_per_user: :undef, bitrate: :undef, user_limit: :undef,
                         permission_overwrites: :undef, parent_id: :undef, rtc_region: :undef,
                         video_quality_mode: :undef, default_auto_archive_duration: :undef, reason: :undef, **rest)
        data = {
          name: name,
          icon: icon,
          type: type,
          position: position,
          topic: topic,
          nsfw: nsfw,
          rate_limit_per_user: rate_limit_per_user,
          bitrate: bitrate,
          user_limit: user_limit,
          permission_overwrites: permission_overwrites,
          parent_id: parent_id,
          rtc_region: rtc_region,
          video_quality_mode: video_quality_mode,
          default_auto_archive_duration: default_auto_archive_duration,
          **rest
        }

        request Route[:PATCH, "/channels/#{channel_id}", channel_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#deleteclose-channel
      # @return [Hash<Symbol, Object>]
      def delete_channel(channel_id, reason: :undef)
        request Route[:DELETE, "/channels/#{channel_id}", channel_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#get-channel-messages
      # @return [Array<Hash<Symbol, Object>>]
      def get_channel_messages(channel_id, around: :undef, before: :undef, after: :undef, limit: :undef, **params)
        request Route[:GET, "/channels/#{channel_id}/messages", channel_id],
                params: filter_undef({ around: around, before: before, after: after, limit: limit, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#get-channel-message
      # @return [Hash<Symbol, Object>]
      def get_channel_message(channel_id, message_id, **params)
        request Route[:GET, "/channels/#{channel_id}/message/#{message_id}", channel_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#create-message
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

      # @!discord_api https://discord.com/developers/docs/resources/channel#crosspost-message
      # @return [Hash<Symbol, Object>]
      def crosspost_message(channel_id, message_id, **rest)
        request Route[:POST, "/channels/#{channel_id}/messages/#{message_id}/crosspost", channel_id],
                body: rest
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#create-reaction
      # @return [nil]
      def create_reaction(channel_id, message_id, emoji)
        request Route[:PUT, "/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji}/@me", channel_id],
                body: ''
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#delete-own-reaction
      # @return [nil]
      def delete_own_reaction(channel_id, message_id, emoji)
        request Route[:DELETE, "/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji}/@me", channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#delete-user-reaction
      # @return [nil]
      def delete_user_reaction(channel_id, message_id, emoji, user_id)
        request Route[:DELETE,
                      "/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji}/#{user_id}",
                      channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#get-reactions
      # @return [Array<Hash<Symbol, Object>>]
      def get_reactions(channel_id, message_id, emoji, after: :undef, limit: :undef, **params)
        query = {
          after: after,
          limit: limit,
          **params
        }

        request Route[:GET, "/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji}", channel_id],
                params: filter_undef(query)
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#delete-all-reactions
      # @return [nil]
      def delete_all_reactions(channel_id, message_id)
        request Route[:DELETE, "/channels/#{channel_id}/messages/#{message_id}/reactions", channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#delete-all-reactions-for-emoji
      # @return [nil]
      def delete_all_reactions_for_emoji(channel_id, message_id, emoji)
        request Route[:DELETE, "/channels/#{channel_id}/messages/#{message_id}/reactions/#{emoji}", channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#edit-message
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
                              **rest
                            })

        body = { file: file, payload_json: JSON.dump(body) } if file

        request Route[:PATCH, "/channels/#{channel_id}/messages/#{message_id}", channel_id],
                body: body
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#delete-message
      # @return [nil]
      def delete_message(channel_id, message_id, reason: :undef)
        request Route[:DELETE, "/channels/#{channel_id}/messages/#{message_id}"],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#bulk-delete-messages
      # @return [nil]
      def bulk_delete_messages(channel_id, messages, reason: :undef)
        request Route[:POST, "/channels/#{channel_id}/messages/bulk-delete", channel_id],
                body: messages,
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#edit-channel-permissions
      # @return [nil]
      def edit_channel_permissions(channel_id, overwrite_id,
                                   allow: :undef, deny: :undef, type: :undef, reason: :undef, **rest)
        request Route[:PUT, "/channels/#{channel_id}/permissions/#{overwrite_id}", channel_id],
                body: filter_undef({ allow: allow, deny: deny, type: type, **rest }),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#get-channel-invites
      # @return [Array<Hash<Symbol, Object>>]
      def get_channel_invites(channel_id, **params)
        request Route[:GET, "/channels/#{channel_id}/invites", channel_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#create-channel-invite
      # @return [Hash<Symbol, Object>]
      def create_channel_invite(channel_id,
                                max_age: :undef, max_uses: :undef, temporary: :undef, unique: :undef,
                                target_type: :undef, target_user_id: :undef, target_application_id: :undef,
                                reason: :undef, **rest)
        data = {
          max_age: max_age,
          max_uses: max_uses,
          temporary: temporary,
          unique: unique,
          target_type: target_type,
          target_user_id: target_user_id,
          target_application_id: target_application_id,
          **rest
        }

        request Route[:POST, "/channels/#{channel_id}/invites", channel_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#delete-channel-permission
      # @return [nil]
      def delete_channel_permission(channel_id, overwrite_id, reason: :undef)
        request Route[:DELETE, "/channels/#{channel_id}/permissions/#{overwrite_id}", channel_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#follow-news-channel
      # @return [Hash<Symbol, Object>]
      def follow_news_channel(channel_id, webhook_channel_id:)
        request Route[:POST, "/channels/#{channel_id}/followers", channel_id],
                body: { webhook_channel_id: webhook_channel_id }
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#trigger-typing-indicator
      # @return [nil]
      def trigger_typing_indicator(channel_id, **rest)
        request Route[:POST, "/channels/#{channel_id}/typing", channel_id],
                body: rest
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#get-pinned-messages
      # @return [Array<Hash<Symbol, Object>>]
      def get_pinned_messages(channel_id, **params)
        request Route[:GET, "/channels/#{channel_id}/pins", channel_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#pin-message
      # @return [nil]
      def pin_message(channel_id, message_id, reason: :undef)
        request Route[:PUT, "/channels/#{channel_id}/pins/#{message_id}", channel_id],
                body: '',
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#unpin-message
      # @return [nil]
      def unpin_message(channel_id, message_id, reason: :undef)
        request Route[:DELETE, "/channels/#{channel_id}/pins/#{message_id}", channel_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#start-thread-with-message
      # @return [Hash<Symbol, Object>]
      def start_thread_with_message(channel_id, message_id,
                                    name:, auto_archive_duration: :undef, reason: :undef, **rest)
        data = {
          name: name,
          auto_archive_duration: auto_archive_duration,
          **rest
        }

        request Route[:POST, "/channels/#{channel_id}/messages/#{message_id}/threads", channel_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#start-thread-without-message
      # @return [Hash<Symbol, Object>]
      def start_thread_without_message(channel_id,
                                       name:, auto_archive_duration: :undef, type: :undef, invitable: :undef,
                                       reason: :undef, **rest)
        data = {
          name: name,
          auto_archive_duration: auto_archive_duration,
          type: type,
          invitable: invitable,
          **reason
        }

        request Route[:POST, "/channels/#{channel_id}/threads", channel_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#join-thread
      # @return [nil]
      def join_thread(channel_id)
        request Route[:PUT, "/channels/#{channel_id}/thread-members/@me", channel_id],
                body: ''
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#add-thread-member
      # @return [nil]
      def add_thread_member(channel_id, user_id)
        request Route[:PUT, "/channels/#{channel_id}/thread-members/#{user_id}", channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#leave-thread
      # @return [nil]
      def leave_thread(channel_id)
        request Route[:DELETE, "/channels/#{channel_id}/thread-members/@me", channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#remove-thread-member
      # @return [nil]
      def remove_thread_member(channel_id, user_id)
        request Route[:DELETE, "/channels/#{channel_id}/thread-members/#{user_id}", channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#remove-thread-member
      # @return [Array<Hash<Symbol, Object>>]
      def list_thread_members(channel_id, **params)
        request Route[:GET, "/channels/#{channel_id}/thread-members", channel_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#list-thread-members
      # @return [Array<Hash<Symbol, Object>>]
      def list_active_threads(channel_id, **params)
        request Route[:GET, "/channels/#{channel_id}/threads/active", channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#list-public-archived-threads
      # @return [Array<Hash<Symbol, Object>>]
      def list_public_archived_threads(channel_id, before: :undef, limit: :undef, **params)
        request Route[:GET, "/channels/#{channel_id}/threads/archived/public", channel_id],
                params: filter_undef({ before: before, limit: limit, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#list-private-archived-threads
      # @return [Array<Hash<Symbol, Object>>]
      def list_private_archived_threads(channel_id, before: :undef, limit: :undef, **params)
        request Route[:GET, "/channels/#{channel_id}/threads/archived/private", channel_id],
                params: filter_undef({ before: before, limit: limit, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#list-joined-private-archived-threads
      # @return [Array<Hash<Symbol, Object>>]
      def list_joined_private_archived_threads(channel_id, before: :undef, limit: :undef, **params)
        request Route[:GET, "/channels/#{channel_id}/users/@me/threads/archived/private"],
                params: filter_undef({ before: before, limit: limit, **params })
      end
    end
  end
end
