# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/guild
    module GuildEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/guild#create-guild
      # @param name [String] 2-100 character name.
      # @param icon [String, #read] A base64 encoded string with the image data.
      # @param verification_level [Integer] Required verification level for members; 0-4.
      # @param default_message_notifications [Integer] Default message notification level; 0-1.
      # @param explicit_content_filter [Integer] Explicit content filter level; 0-2.
      # @param roles [Array<Hash<Symbol, Object>>] Array of new roles to create.
      # @param channels [Array<Hash>] Array of new channels to create.
      # @param afk_channel_id [Integer, String] ID for the AFK channel.
      # @param afk_timeout [Integer] AFK timeout in seconds.
      # @param system_channel_id [Integer, String] Where messages such as welcomes and boosts should be posted.
      # @param system_channel_flags [Integer] Bitwise value of system channel flags.
      # @return [Hash<Symbol, Object>]
      def create_guild(name:, icon: :undef, verification_level: :undef,
                       default_message_notifications: :undef, explicit_content_filter: :undef, roles: :undef,
                       channels: :undef, afk_channel_id: :undef, afk_timeout: :undef, system_channel_id: :undef,
                       system_channel_flags: :undef, **rest)
        data = {
          name: name,
          icon: icon,
          verification_level: verification_level,
          default_message_notifications: default_message_notifications,
          explicit_content_filter: explicit_content_filter,
          roles: roles,
          channels: channels,
          afk_channel_id: afk_channel_id,
          afk_timeout: afk_timeout,
          system_channel_id: system_channel_id,
          system_channel_flags: system_channel_flags,
          **rest
        }

        request Route[:POST, '/guilds'],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param with_counts [Boolean] Whether to include an approximate member count.
      # @return [Hash<Symbol, Object>]
      def get_guild(guild_id, with_counts: :undef, **params)
        request Route[:GET, "/guilds/#{guild_id}", guild_id],
                params: filter_undef({ with_counts: with_counts, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-preview
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Hash<Symbol, Object>]
      def get_guild_preview(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/preview", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-guild
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param name [String] 2-100 character name.
      # @param verification_level [String] Required verification level for members; 0-4.
      # @param default_message_notifications [Integer] Default message notification level; 0-1.
      # @param explicit_content_filter [Integer] Explicit content filter level; 0-2.
      # @param afk_channel_id [Integer, String] ID for the AFK channel.
      # @param afk_timeout [Integer] AFK timeout in seconds.
      # @param icon [String, #read] A base64 encoded string with the image data.
      # @param owner_id [Integer, String] ID of the new guild owner.
      # @param splash [String, #read] A base64 encoded string with the image data.
      # @param discovery_splash [String, #read] A base64 encoded string with the image data.
      # @param banner [String, #read] A base64 encoded string with the image data.
      # @param system_channel_id [Integer, String] Where messages such as welcomes and boosts should be posted.
      # @param system_channel_flags [Integer] Bitwise value of system channel flags.
      # @param rules_channel_id [Integer, String] ID of the channel to mark as that guild's rules channels.
      # @param public_updates_channel_id [Integer, String] ID of the channel where server staff reccive updates from Discord.
      # @param preferred_locale [String] preferred locale of a guild used in server discovery. Default is "en-US".
      # @param features [Array<String>] Array of strings that specifiy enabled features for this guild.
      # @param description [String] Description for this guild.
      # @param premium_progress_bar_enabled [Boolean] Whether the boost progress bar should be visible.
      # @param safety_alerts_channel_id [Integer, String] Channel where safety alerts should be sent from Discord.
      # @param reason [String] The reason for modifiying this guild.
      # @return [Hash<Symbol, Object>]
      def modify_guild(guild_id, name: :undef, verification_level: :undef,
                       default_message_notifications: :undef, explicit_content_filter: :undef, afk_channel_id: :undef,
                       afk_timeout: :undef, icon: :undef, owner_id: :undef, splash: :undef, discovery_splash: :undef,
                       banner: :undef, system_channel_id: :undef, system_channel_flags: :undef,
                       rules_channel_id: :undef, public_updates_channel_id: :undef, preferred_locale: :undef,
                       features: :undef, description: :undef, premium_progress_bar_enabled: :undef,
                       safety_alerts_channel_id: :undef, reason: :undef, **rest)
        data = {
          name: name,
          verification_level: verification_level,
          default_message_notifications: default_message_notifications,
          explicit_content_filter: explicit_content_filter,
          afk_channel_id: afk_channel_id,
          afk_timeout: afk_timeout,
          icon: icon,
          owner_id: owner_id,
          splash: splash,
          discovery_splash: discovery_splash,
          banner: banner,
          system_channel_id: system_channel_id,
          system_channel_flags: system_channel_flags,
          rules_channel_id: rules_channel_id,
          public_updates_channel_id: public_updates_channel_id,
          preferred_locale: preferred_locale,
          features: features,
          description: description,
          premium_progress_bar_enabled: premium_progress_bar_enabled,
          safety_alerts_channel_id: safety_alerts_channel_id,
          **rest
        }

        request Route[:PATCH, "/guilds/#{guild_id}", guild_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#delete-guild
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [nil]
      def delete_guild(guild_id)
        request Route[:DELETE, "/guilds/#{guild_id}", guild_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-channels
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_channels(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/channels", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#create-guild-channel
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param name [String] 1-100 character name.
      # @param type [Integer] Type of channel to create.
      # @param topic [String] 0-1024 character topic.
      # @param bitrate [Integer] Bitrate in bits of the voice channel.
      # @param user_limit [Integer] Max amount of users that can be in this voice channel.
      # @param rate_limit_per_user [Integer] Time between 0-21600 that a user has to wait between messages.
      # @param position [Integer] Sorting position of the channel.
      # @param permission_overwrites [Array<Hash<Symbol, Object>>] Permission overwrites for this channel.
      # @param parent_id [Integer, String] The parent category of this channel.
      # @param nsfw [Boolean] Whether this channel is age-restricted or not.
      # @param rtc_region [String] Voice region of the voice channel.
      # @param video_quality_mode [Integer] Camera quality mode of the voice channel.
      # @param default_auto_archive_duration [Integer] Default client duration to auto-archive new threads.
      # @param default_reaction_emoji [Hash<Symbol, Object>] Emoji to show for reactions on posts in GUILD_FORUM channels.
      # @param available_tags [Array<Hash<Symbol, Object>>] Avalibile tags for posts in GUILD_FORUM channels.
      # @param default_sort_order [Integer] Default sort order for GUILD_FORUM channels.
      # @param default_forum_layout [Integer] Default forum layout for GUILD_FORUM channels.
      # @param default_thread_rate_limit_per_user [Integer] Inital rate-limit-per-user for new threads.
      # @param reason [String] The reason for creating this channel.
      # @return [Hash<Symbol, Object>]
      def create_guild_channel(guild_id, name:, type: :undef, topic: :undef, bitrate: :undef, user_limit: :undef,
                               rate_limit_per_user: :undef, position: :undef, permission_overwrites: :undef,
                               parent_id: :undef, nsfw: :undef, rtc_region: :undef, video_quality_mode: :undef,
                               default_auto_archive_duration: :undef, default_reaction_emoji: :undef,
                               available_tags: :undef, default_sort_order: :undef, default_forum_layout: :undef,
                               default_thread_rate_limit_per_user: :undef, reason: :undef, **rest)
        data = {
          name: name,
          type: type,
          topic: topic,
          bitrate: bitrate,
          user_limit: user_limit,
          rate_limit_per_user: rate_limit_per_user,
          position: position,
          permission_overwrites: permission_overwrites,
          parent_id: parent_id,
          nsfw: nsfw,
          rtc_region: rtc_region,
          video_quality_mode: video_quality_mode,
          default_auto_archive_duration: default_auto_archive_duration,
          default_reaction_emoji: default_reaction_emoji,
          available_tags: available_tags,
          default_sort_order: default_sort_order,
          default_forum_layout: default_forum_layout,
          default_thread_rate_limit_per_user: default_thread_rate_limit_per_user,
          **rest
        }

        request Route[:POST, "/guilds/#{guild_id}/channels", guild_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-guild-channel-positions
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param channels [Array<Hash<Symbol, Object>>] An array of channel objects.
      # @return [nil]
      def modify_guild_channel_positions(guild_id, channels)
        request Route[:PATCH, "/guilds/#{guild_id}/channels", guild_id],
                body: channels
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#list-active-guild-threads
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Hash<Symbol,Object>]
      def list_active_guild_threads(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/threads/active"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-member
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param user_id [Integer, String] An ID that uniquely identifies a user.
      # @return [Hash<Symbol, Object>]
      def get_guild_member(guild_id, user_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/members/#{user_id}", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-preview
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param limit [Integer] 1-1000 max number of members to return.
      # @param after [Integer, String] Highest user ID on the previous page.
      # @return [Array<Hash<Symbol, Object>>]
      def list_guild_members(guild_id, limit: :undef, after: :undef, **params)
        request Route[:GET, "/guilds/#{guild_id}/members", guild_id],
                params: filter_undef({ limit: limit, after: after, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#search-guild-members
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param query [String] Usernames or nicknames to search against.
      # @param limit [Integer] 1-1000 max number of members to return.
      # @return [Array<Hash<Symbol, Object>>]
      def search_guild_members(guild_id, query:, limit: :undef, **params)
        request Route[:GET, "/guilds/#{guild_id}/members/search", guild_id],
                params: filter_undef({ query: query, limit: limit, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#add-guild-member
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param user_id [Integer, String] An ID that uniquely identifies a user.
      # @param access_token [String] oauth2 access token with the guilds.join scope.
      # @param nick [String] The nickname they should be assigned.
      # @param roles [Array<Integer, String>] Array of role ID's to assign to the member.
      # @param mute [Boolean] Whether this user should be muted in voice channels.
      # @param deaf [Boolean] Whether this user should be deafened in voice channels.
      # @return [Hash<Symbol, Object>]
      def add_guild_member(guild_id, user_id, access_token:, nick: :undef, roles: :undef, mute: :undef, deaf: :undef,
                           **rest)
        data = {
          access_token: access_token,
          nick: nick,
          roles: roles,
          mute: mute,
          deaf: deaf,
          **rest
        }

        request Route[:PUT, "/guilds/#{guild_id}/members/#{user_id}", guild_id],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-guild-member
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param user_id [Integer, String] An ID that uniquely identifies a user.
      # @param nick [String] The user's new nickname.
      # @param roles [Array<Integer, String>] Array of role ID's to assign to the member.
      # @param mute [Boolean] Whether this user should be muted in voice channels.
      # @param deaf [Boolean] Whether this user should be deafened in voice channels.
      # @param channel_id [Integer, String] ID of the voice channel to move the user to.
      # @param communication_disabled_until [Time] When the user's timeout should expire.
      # @param reason [String] The reason for modifiying this guild member.
      # @return [Hash<Symbol, Object>]
      def modify_guild_member(guild_id, user_id, nick: :undef, roles: :undef, mute: :undef, deaf: :undef,
                              channel_id: :undef, communication_disabled_until: :undef, reason: :undef, **rest)
        data = {
          nick: nick,
          roles: roles,
          mute: mute,
          deaf: deaf,
          channel_id: channel_id,
          communication_disabled_until: communication_disabled_until,
          **rest
        }

        request Route[:PATCH, "/guilds/#{guild_id}/members/#{user_id}", guild_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-current-member
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param nick [String] The user's new nickname.
      # @param reason [String] The reason for modifiying yourself.
      # @return [Hash<Symbol, Object>]
      def modify_current_member(guild_id, nick: :undef, reason: :undef, **rest)
        request Route[:PATCH, "/guilds/#{guild_id}/members/@me", guild_id],
                body: filter_undef({ nick: nick, **rest }),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#add-guild-member-role
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param user_id [Integer, String] An ID that uniquely identifies a user.
      # @param role_id [Integer, String] An ID that uniquely identifies a role.
      # @param reason [String] The reason for adding a role to this member.
      # @return [nil]
      def add_guild_member_role(guild_id, user_id, role_id, reason: :undef)
        request Route[:PUT, "/guilds/#{guild_id}/members/#{user_id}/roles/#{role_id}", guild_id],
                body: '',
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#remove-guild-member-role
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param user_id [Integer, String] An ID that uniquely identifies a user.
      # @param role_id [Integer, String] An ID that uniquely identifies a role.
      # @param reason [String] The reason for removing a role from this member.
      # @return [nil]
      def remove_guild_member_role(guild_id, user_id, role_id, reason: :undef)
        request Route[:DELETE, "/guilds/#{guild_id}/members/#{user_id}/roles/#{role_id}", guild_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#remove-guild-member
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param user_id [Integer, String] An ID that uniquely identifies a user.
      # @param reason [String] The reason for removing this member.
      # @return [nil]
      def remove_guild_member(guild_id, user_id, reason: :undef)
        request Route[:DELETE, "/guilds/#{guild_id}/members/#{user_id}", guild_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-bans
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param limit [Integer] Max number of banned users to return up to 1000.
      # @param before [Integer, String] Get users only before this ID.
      # @param after [Integer, String] Get users only after this ID.
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_bans(guild_id, limit: :undef, before: :undef, after: :undef, **params)
        request Route[:GET, "/guilds/#{guild_id}/bans", guild_id],
                params: filter_undef({ limit: limit, before: before, after: after, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-ban
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param user_id [Integer, String] An ID that uniquely identifies a user.
      # @return [Hash<Symbol, Object>]
      def get_guild_ban(guild_id, user_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/bans/#{user_id}", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#create-guild-ban
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param user_id [Integer, String] An ID that uniquely identifies a user.
      # @param delete_message_seconds [Integer] Number between 0-604800 to delete messages for.
      # @return [nil]
      def create_guild_ban(guild_id, user_id, delete_message_seconds: :undef, reason: :undef, **rest)
        request Route[:PUT, "/guilds/#{guild_id}/bans/#{user_id}", guild_id],
                body: filter_undef({ delete_message_seconds: delete_message_seconds, **rest }),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#remove-guild-ban
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param user_id [Integer, String] An ID that uniquely identifies a user.
      # @param reason [String] The reason for removing this user's ban.
      # @return [nil]
      def remove_guild_ban(guild_id, user_id, reason: :undef)
        request Route[:DELETE, "/guilds/#{guild_id}/bans/#{user_id}", guild_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#bulk-guild-ban
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param user_ids [Array<String>] An array containing user ID's to ban.
      # @param delete_message_seconds [Integer] Number between 0-604800 to delete messages for.
      # @return [Hash<Symbol, Object>]
      def bulk_guild_ban(guild_id, user_ids, delete_message_seconds: :undef, reason: :undef, **rest)
        data = {
          user_ids: user_ids,
          delete_message_seconds: delete_message_seconds,
          **rest
        }

        request Route[:POST, "/guilds/#{guild_id}/bulk-ban", guild_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-roles
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_roles(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/roles", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-role
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param role_id [Integer, String] An ID that uniquely identifies a role.
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_role(guild_id, role_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/roles/#{role_id}", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#create-guild-role
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param name [String] Name of the role to create.
      # @param permissions [String] Bitwise permissions for this role.
      # @param color [Integer] An RGB color value for this role.
      # @param hoist [Boolean] Whether this role's members should be displayed seperately in the sidebar.
      # @param icon [String, #read] An icon to display next to this role.
      # @param unicode_emoji [String] Unicode emoji for the role.
      # @param mentionable [Boolean] Whether everyone should be able to mention this role.
      # @param reason [String] The reason for creating this role.
      # @return [Hash<Symbol, Object>]
      def create_guild_role(guild_id, name: :undef, permissions: :undef, color: :undef, hoist: :undef, icon: :undef,
                            unicode_emoji: :undef, mentionable: :undef, reason: :undef, **rest)
        data = {
          name: name,
          permissions: permissions,
          color: color,
          hoist: hoist,
          icon: icon,
          unicode_emoji: unicode_emoji,
          mentionable: mentionable,
          **rest
        }

        request Route[:POST, "/guilds/#{guild_id}/roles", guild_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-guild-role-positions
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param roles [Array<Hash<Symbol, Object>>] Role objects sorted in their new positions.
      # @param reason [String] The reason for modifiying the positions of this role.
      # @return [Array<Hash<Symbol, Object>>]
      def modify_guild_role_positions(guild_id, roles, reason: :undef)
        request Route[:PATCH, "/guilds/#{guild_id}/roles", guild_id],
                body: roles,
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-guild-role
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param role_id [Integer, String] An ID that uniquely identifies a role.
      # @param name [String] New name of the role.
      # @param permissions [String] Bitwise permissions for this role.
      # @param color [Integer] An RGB color value for this role.
      # @param hoist [Boolean] Whether this role's members should be displayed seperately in the sidebar.
      # @param icon [String, #read] An icon to display next to this role.
      # @param unicode_emoji [String] Unicode emoji for the role.
      # @param mentionable [Boolean] Whether everyone should be able to mention this role.
      # @param reason [String] The reason for modifiying this role.
      # @return [Hash<Symbol, Object>]
      def modify_guild_role(guild_id, role_id, name: :undef, permissions: :undef, color: :undef, hoist: :undef,
                            icon: :undef, unicode_emoji: :undef, mentionable: :undef, reason: :undef, **rest)
        data = {
          name: name,
          permissions: permissions,
          color: color,
          hoist: hoist,
          icon: icon,
          unicode_emoji: unicode_emoji,
          mentionable: mentionable,
          **rest
        }

        request Route[:PATCH, "/guilds/#{guild_id}/roles/#{role_id}", guild_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-guild-mfa-level
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param level [Integer] The new MFA level; either 0 or 1.
      # @param reason [String] The reason for modifiying the MFA level.
      # @return [Intger]
      def modify_guild_mfa_level(guild_id, level:, reason: :undef, **rest)
        request Route[:POST, "/guilds/#{guild_id}/mfa", guild_id],
                body: filter_undef({ level: level, **rest }),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#delete-guild-role
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param role_id [Integer, String] An ID that uniquely identifies a role.
      # @param reason [String] The reason for deleting this role.
      # @return [nil]
      def delete_guild_role(guild_id, role_id, reason: :undef)
        request Route[:DELETE, "/guilds/#{guild_id}/roles/#{role_id}", guild_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-prune-count
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param days [Integer] Number of days between 1-30 to count for.
      # @param include_roles [String] comma-delimited array of role ID's.
      # @return [Hash<Symbol, Object>]
      def get_guild_prune_count(guild_id, days: :undef, include_roles: :undef, **params)
        request Route[:GET, "/guilds/#{guild_id}/prune", guild_id],
                params: filter_undef({ days: days, include_roles: include_roles, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#begin-guild-prune
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param days [Integer] Number of days between 1-30 to prune for.
      # @param compute_prune_count [Boolean] Whether to return the prune key.
      # @param include_roles [Array<String, Integer>] Array of role ID's to include.
      # @param reason [String] The reason for initiating a prune.
      # @return [Hash<Symbol, Object>]
      def begin_guild_prune(guild_id, days: :undef, compute_prune_count: :undef, include_roles: :undef, reason: :undef,
                            **rest)
        data = {
          days: days,
          compute_prune_count: compute_prune_count,
          include_roles: include_roles,
          **rest
        }

        request Route[:POST, "/guilds/#{guild_id}/prune", guild_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-voice-regions
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_voice_regions(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/regions", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-invites
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_invites(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/invites", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-integrations
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_integrations(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/integrations", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#delete-guild-integration
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param integration_id [Integer, String] An ID that uniquely identifies an integration.
      # @param reason [String] The reason for deleting this integration.
      # @return [nil]
      def delete_guild_integration(guild_id, integration_id, reason: :undef)
        request Route[:DELETE, "/guilds/#{guild_id}/integrations/#{integration_id}", guild_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-widget-settings
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Hash<Symbol, Object>]
      def get_guild_widget_settings(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/widget", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-guild-widget
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param enabled [Boolean] Whether the widget is enabled.
      # @param channel_id [Integer, String] The channel ID of the widget.
      # @param reason [String] The reason for modifiying the guild widget.
      # @return [Hash<Symbol, Object>]
      def modify_guild_widget(guild_id, enabled: :undef, channel_id: :undef, reason: :undef, **rest)
        request Route[:PATCH, "/guilds/#{guild_id}/widget", guild_id],
                params: filter_undef({ enabled: enabled, channel_id: channel_id, **rest }),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-widget
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Hash<Symbol, Object>]
      def get_guild_widget(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/widget.json", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-vanity-url
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Hash<Symbol, Object>]
      def get_guild_vanity_url(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/vanity-url", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-widget-image
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param style [String] Style of the widget image to return.
      # @return [String]
      def get_guild_widget_image(guild_id, style: :undef, **params)
        request Route[:GET, "/guilds/#{guild_id}/widget.png", guild_id],
                params: filter_undef({ style: style, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-welcome-screen
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Hash<Symbol, Object>]
      def get_guild_welcome_screen(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/welcome-screen", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-guild-welcome-screen
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param enabled [Boolean] Whether the welcome screen should be enabled.
      # @param welcome_channels [Array<Symbol, Object>] Array of welcome screen channel objects.
      # @param description [String] Server description to show on the welcome screen.
      # @param reason [String] The reason for modifiying the welcome screen.
      # @return [Hash<Symbol, Object>]
      def modify_guild_welcome_screen(guild_id, enabled: :undef, welcome_channels: :undef, description: :undef,
                                      reason: :undef, **rest)
        data = {
          enabled: enabled,
          welcome_channels: welcome_channels,
          description: description,
          **rest
        }

        request Route[:PATCH, "/guilds/#{guild_id}/welcome-screen", guild_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-onboarding
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Hash<Symbol, Object>]
      def get_guild_onboarding(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/onboarding", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-guild-onboarding
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # prompts [Hash] Array of onboarding prompt objects.
      # default_channel_ids [Array<Integer, String>] Array of channel ID's members get added to by default.
      # enabled [Boolean] Whether onboarding is enabled or not.
      # reason [String] Reason for modifiying this server's onboarding.
      # @return [Hash<Symbol, Object>]
      def modify_guild_onboarding(guild_id, prompts:, default_channel_ids:, enabled:, mode:,
                                  reason: :undef, **rest)
        data = {
          prompts: prompts,
          default_channel_ids: default_channel_ids,
          enabled: enabled,
          mode: mode,
          **rest
        }

        request Route[:PUT, "/guilds/#{guild_id}/onboarding", guild_id],
                body: filter_undef(data),
                reason: reason
      end
    end
  end
end
