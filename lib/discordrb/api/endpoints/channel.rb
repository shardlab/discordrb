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
      # @param rtc_region [String] Channel voice region. Defaults to auto when null.
      # @param video_quality_mode [Integer] Camera quality mode in voice channels.
      # @param default_auto_archive_duration [Integer] Default client duration to auto-archive new threads.
      # @param flags [Integer] Bitfield value of channel flags to set.
      # @param available_tags [Array<Hash<Symbol, Object>>] Avalibile tags for posts in GUILD_FORUM channels.
      # @param default_reaction_emoji [Hash<Symbol, Object>] Emoji to show for reactions on posts in GUILD_FORUM channels.
      # @param default_thread_rate_limit_per_user [Integer] Inital rate-limit-per-user for new threads.
      # @param default_sort_order [Integer] Default sort order for GUILD_FORUM channels.
      # @param default_forum_layout [Integer] Default forum layout for GUILD_FORUM channels.
      # @param reason [String] The reason for making this channel.
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
      # @param allow [String] Bitwise value of allowed permissions. Defaults to "0".
      # @param deny [String] Bitwise value of denied permissions. Defaults to "0".
      # @param type [Integer] 0 for a role, and 1 for a member.
      # @param reason [String] The reason for updating this channel's permissions.
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
      # @param max_age [Integer] How long this invite lasts before expiring in seconds.
      # @param max_uses [Integer] Max number of times this invite can be used; 0-100.
      # @param temporary [Boolean] If this invite only grants temporary membership.
      # @param unique [Boolean] Whether to avoid using a similar type of invite.
      # @param target_type [Integer] Type of target for voice channels.
      # @param target_user_id [Integer, String] ID of the user's stream to display.
      # @param target_application_id [Integer, String] ID of the embedded application to open.
      # @param reason [String] The reason for making this invite.
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
      # @param overwrite_id [Integer, String] An ID that uniquely identifies a channel overwrite.
      # @param reason [String] The reason for deleting this permission overwrite.
      # @return [nil]
      def delete_channel_permission(channel_id, overwrite_id, reason: :undef)
        request Route[:DELETE, "/channels/#{channel_id}/permissions/#{overwrite_id}", channel_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#follow-announcement-channel
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param webhook_channel_id [Integer, String] ID of the channel to target.
      # @return [Hash<Symbol, Object>]
      def follow_announcement_channel(channel_id, webhook_channel_id:)
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
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @param reason [String] The reason for pinning this message.
      # @return [nil]
      def pin_message(channel_id, message_id, reason: :undef)
        request Route[:PUT, "/channels/#{channel_id}/pins/#{message_id}", channel_id],
                body: '',
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#unpin-message
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param message_id [Integer, String] An ID that uniquely identifies a message.
      # @param reason [String] The reason for un-pinning this message.
      # @return [nil]
      def unpin_message(channel_id, message_id, reason: :undef)
        request Route[:DELETE, "/channels/#{channel_id}/pins/#{message_id}", channel_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#start-thread-with-message
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param name [String] 1-100 character name.
      # @param auto_archive_duration [Integer] The thread won't show in the channel list once this duration is reached.
      # @param rate_limit_per_user [Integer] Slowmode, or amount of seconds a user has to wait between messages.
      # @param reason [String] The reason for starting this thread.
      # @return [Hash<Symbol, Object>]
      def start_thread_with_message(channel_id, message_id,
                                    name:, auto_archive_duration: :undef, rate_limit_per_user: :undef,
                                    reason: :undef, **rest)
        data = {
          name: name,
          auto_archive_duration: auto_archive_duration,
          rate_limit_per_user: rate_limit_per_user,
          **rest
        }

        request Route[:POST, "/channels/#{channel_id}/messages/#{message_id}/threads", channel_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#start-thread-without-message
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param name [String] 1-100 character name.
      # @param auto_archive_duration [Integer] The thread won't show in the channel list once this duration is reached.
      # @param type [Integer] Type of thread to make.
      # @param invitable [Boolean] If non-moderators can add other non-moderators to this thread.
      # @param rate_limit_per_user [Integer] Slowmode, or amount of seconds a user has to wait between messages.
      # @param reason [String] The reason for starting this thread.
      # @return [Hash<Symbol, Object>]
      def start_thread_without_message(channel_id,
                                       name:, auto_archive_duration: :undef, type: :undef, invitable: :undef,
                                       rate_limit_per_user: :undef, reason: :undef, **rest)
        data = {
          name: name,
          auto_archive_duration: auto_archive_duration,
          type: type,
          invitable: invitable,
          rate_limit_per_user: rate_limit_per_user,
          **rest
        }

        request Route[:POST, "/channels/#{channel_id}/threads", channel_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#start-thread-in-forum-or-media-channel
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param name [String] 1-100 character name.
      # @param auto_archive_duration [Integer] The thread won't show in the channel list once this duration is reached.
      # @param message [Hash<Symbol, Object>] The first message in a forum or media channel.
      # @param files [File] File contents being sent.
      # @param applied_tags [Array] ID's of tags to apply.
      # @param rate_limit_per_user [Integer] Slowmode, or amount of seconds a user has to wait between messages.
      # @param reason [String] The reason for starting this thread in forum or media channel.
      # @return [Hash<Symbol, Object>]
      def start_thread_in_forum_or_media_channel(channel_id,
                                                 name:, auto_archive_duration: :undef, message:, applied_tags: :undef,
                                                 file: :undef, rate_limit_per_user: :undef, reason: :undef, **rest)
        body = filter_undef({
                              name: name,
                              auto_archive_duration: auto_archive_duration,
                              message: message,
                              applied_tags: applied_tags,
                              rate_limit_per_user: rate_limit_per_user,
                              **rest
                            })

        if files
          files = files.zip(0...files.count).map { |file, index| ["file[#{index}]", file] }.to_h
          body = { **files, payload_json: JSON.dump(body) }
        end

        request Route[:POST, "/channels/#{channel_id}/threads", channel_id],
                body: body,
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
      # @param user_id [Integer, String] An ID that uniquely identifies a user.
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
      # @param user_id [Integer, String] An ID that uniquely identifies a user.
      # @return [nil]
      def remove_thread_member(channel_id, user_id)
        request Route[:DELETE, "/channels/#{channel_id}/thread-members/#{user_id}", channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#get-thread-member
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param user_id [Integer, String] An ID that uniquely identifies a user.
      # @param with_member [Boolean] Whether to return guild member object.
      # @return [nil]
      def get_thread_member(channel_id, user_id, with_member: :undef)
        request Route[:DELETE, "/channels/#{channel_id}/thread-members/#{user_id}", channel_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#remove-thread-member
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param with_member [Boolean] hether to return guild member object.
      # @param before [Integer, String] Thread members to get after this user ID.
      # @param limit [Integer] 1-100 max number of thread members to return.
      # @return [Array<Hash<Symbol, Object>>]
      def list_thread_members(channel_id, with_member: :undef, before: :undef, limit: :undef, **params)
        request Route[:GET, "/channels/#{channel_id}/thread-members", channel_id],
                params: filter_undef({ with_member: with_member, before: before, limit: limit, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#list-public-archived-threads
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param before [Time] Threads archived before this timestamp.
      # @param limit [Integer] Max number of threads to return.
      # @return [Array<Hash<Symbol, Object>>]
      def list_public_archived_threads(channel_id, before: :undef, limit: :undef, **params)
        request Route[:GET, "/channels/#{channel_id}/threads/archived/public", channel_id],
                params: filter_undef({ before: before, limit: limit, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#list-private-archived-threads
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param before [Time] Threads archived before this timestamp.
      # @param limit [Integer] Max number of threads to return.
      # @return [Array<Hash<Symbol, Object>>]
      def list_private_archived_threads(channel_id, before: :undef, limit: :undef, **params)
        request Route[:GET, "/channels/#{channel_id}/threads/archived/private", channel_id],
                params: filter_undef({ before: before, limit: limit, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/channel#list-joined-private-archived-threads
      # @param channel_id [Integer, String] An ID that uniquely identifies a channel.
      # @param before [Integer, String] Threads before this ID.
      # @param limit [Integer] Max number of threads to return.
      # @return [Array<Hash<Symbol, Object>>]
      def list_joined_private_archived_threads(channel_id, before: :undef, limit: :undef, **params)
        request Route[:GET, "/channels/#{channel_id}/users/@me/threads/archived/private"],
                params: filter_undef({ before: before, limit: limit, **params })
      end
    end
  end
end
