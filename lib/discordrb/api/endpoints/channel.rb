# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/channel
    module ChannelEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/channel#get-channel
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [Hash<Symbol, Object>]
      def get_channel(channel_id, **params)
        request Route[:GET, "/channels/#{channel_id}", channel_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#modify-channel
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param name [String] 1-100 character name.
      # @param icon [File, #Read] A base64 encoded string with the image data.
      # @param type [Integer] Type of channel.
      # @param position [Integer] Position of the channel in the channel list.
      # @param topic [String] 0-1024 character topic.
      # @param nsfw [Boolean] If this channel is age-restricted or not.
      # @param rate_limit_per_user [Integer] The wait between sending messages (0-21600).
      # @param bitrate [Intger] the bitrate of the voice or stage channel.
      # @param user_limit [Intger] The max amount of users that can be in this voice or stage channel.
      # @param permission_overwrites [Array<Symbol, Object>] Array of permission overwrite objects for the channel or category.
      # @param parent_id [Integer, String] ID of the new parent category for this channel.
      # @return [Hash<Symbol, Object>]
      def modify_channel(channel_id,
                         name: :undef, icon: :undef, type: :undef, position: :undef, topic: :undef,
                         nsfw: :undef, rate_limit_per_user: :undef, bitrate: :undef, user_limit: :undef,
                         permission_overwrites: :undef, parent_id: :undef, rtc_region: :undef,
                         video_quality_mode: :undef, default_auto_archive_duration: :undef, flags: :undef,
                         available_tags: :undef, default_reaction_emoji: :undef, default_thread_rate_limit_per_user: :undef,
                         default_sort_order: :undef, default_forum_layout: :undef, reason: :undef, **rest)
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
          flags: flags,
          available_tags: available_tags,
          default_reaction_emoji: default_reaction_emoji,
          default_thread_rate_limit_per_user: default_thread_rate_limit_per_user,
          default_sort_order: default_sort_order,
          default_forum_layout: default_forum_layout,
          **rest
        }

        request Route[:PATCH, "/channels/#{channel_id}", channel_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#deleteclose-channel
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param reason [String] Reason for deleting this channel.
      # @return [Hash<Symbol, Object>]
      def delete_channel(channel_id, reason: :undef)
        request Route[:DELETE, "/channels/#{channel_id}", channel_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#edit-channel-permissions
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [nil]
      def edit_channel_permissions(channel_id, overwrite_id,
                                   allow: :undef, deny: :undef, type: :undef, reason: :undef, **rest)
        request Route[:PUT, "/channels/#{channel_id}/permissions/#{overwrite_id}", channel_id],
                body: filter_undef({ allow: allow, deny: deny, type: type, **rest }),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#get-channel-invites
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [Array<Hash<Symbol, Object>>]
      def get_channel_invites(channel_id, **params)
        request Route[:GET, "/channels/#{channel_id}/invites", channel_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#create-channel-invite
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
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
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [nil]
      def delete_channel_permission(channel_id, overwrite_id, reason: :undef)
        request Route[:DELETE, "/channels/#{channel_id}/permissions/#{overwrite_id}", channel_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#follow-news-channel
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [Hash<Symbol, Object>]
      def follow_news_channel(channel_id, webhook_channel_id:)
        request Route[:POST, "/channels/#{channel_id}/followers", channel_id],
                body: { webhook_channel_id: webhook_channel_id }
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#trigger-typing-indicator
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [nil]
      def trigger_typing_indicator(channel_id, **rest)
        request Route[:POST, "/channels/#{channel_id}/typing", channel_id],
                body: rest
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#get-pinned-messages
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [Array<Hash<Symbol, Object>>]
      def get_pinned_messages(channel_id, **params)
        request Route[:GET, "/channels/#{channel_id}/pins", channel_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#pin-message
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [nil]
      def pin_message(channel_id, message_id, reason: :undef)
        request Route[:PUT, "/channels/#{channel_id}/pins/#{message_id}", channel_id],
                body: '',
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#unpin-message
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [nil]
      def unpin_message(channel_id, message_id, reason: :undef)
        request Route[:DELETE, "/channels/#{channel_id}/pins/#{message_id}", channel_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#start-thread-with-message
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
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
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
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
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [nil]
      def join_thread(channel_id)
        request Route[:PUT, "/channels/#{channel_id}/thread-members/@me", channel_id],
                body: ''
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#add-thread-member
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [nil]
      def add_thread_member(channel_id, user_id)
        request Route[:PUT, "/channels/#{channel_id}/thread-members/#{user_id}", channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#leave-thread
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [nil]
      def leave_thread(channel_id)
        request Route[:DELETE, "/channels/#{channel_id}/thread-members/@me", channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#remove-thread-member
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [nil]
      def remove_thread_member(channel_id, user_id)
        request Route[:DELETE, "/channels/#{channel_id}/thread-members/#{user_id}", channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#remove-thread-member
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [Array<Hash<Symbol, Object>>]
      def list_thread_members(channel_id, **params)
        request Route[:GET, "/channels/#{channel_id}/thread-members", channel_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#list-thread-members
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [Array<Hash<Symbol, Object>>]
      def list_active_threads(channel_id, **params)
        request Route[:GET, "/channels/#{channel_id}/threads/active", channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#list-public-archived-threads
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [Array<Hash<Symbol, Object>>]
      def list_public_archived_threads(channel_id, before: :undef, limit: :undef, **params)
        request Route[:GET, "/channels/#{channel_id}/threads/archived/public", channel_id],
                params: filter_undef({ before: before, limit: limit, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#list-private-archived-threads
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [Array<Hash<Symbol, Object>>]
      def list_private_archived_threads(channel_id, before: :undef, limit: :undef, **params)
        request Route[:GET, "/channels/#{channel_id}/threads/archived/private", channel_id],
                params: filter_undef({ before: before, limit: limit, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#list-joined-private-archived-threads
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @return [Array<Hash<Symbol, Object>>]
      def list_joined_private_archived_threads(channel_id, before: :undef, limit: :undef, **params)
        request Route[:GET, "/channels/#{channel_id}/users/@me/threads/archived/private"],
                params: filter_undef({ before: before, limit: limit, **params })
      end
    end
  end
end
