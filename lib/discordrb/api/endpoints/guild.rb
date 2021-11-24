# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/guild
    module GuildEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/guild#create-guild
      # @return [Hash<Symbol, Object>]
      def create_guild(name:, region: :undef, icon: :undef, verification_level: :undef,
                       default_message_notifications: :undef, explicit_content_filter: :undef, roles: :undef,
                       channels: :undef, afk_channel_id: :undef, afk_timeout: :undef, system_channel_id: :undef,
                       system_channel_flags: :undef, **rest)
        data = {
          name: name,
          region: region,
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
      # @return [Hash<Symbol, Object>]
      def get_guild(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-preview
      # @return [Hash<Symbol, Object>]
      def get_guild_preview(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/preview", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-guild
      # @return [Hash<Symbol, Object>]
      def modify_guild(guild_id, name: :undef, region: :undef, verification_level: :undef,
                       default_message_notifications: :undef, explicit_content_filter: :undef, afk_channel_id: :undef,
                       afk_timeout: :undef, icon: :undef, owner_id: :undef, splash: :undef, discovery_splash: :undef,
                       banner: :undef, system_channel_id: :undef, system_channel_flags: :undef,
                       rules_channel_id: :undef, public_updates_channel_id: :undef, preferred_locale: :undef,
                       features: :undef, description: :undef, **rest)
        data = {
          name: name,
          region: region,
          verification_level: verification_level,
          default_message_notifications:default_message_notifications,
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
          **rest
        }

        request Route[:PATCH, "/guilds/#{guild_id}", guild_id],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#delete-guild
      # @return [nil]
      def delete_guild(guild_id)
        request Route[:DELETE, "/guilds/#{guild_id}", guild_id]
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-channels
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_channels(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/channels", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#create-guild-channel
      # @return [Hash<Symbol, Object>]
      def create_guild_channel(guild_id, name:, type: :undef, topic: :undef, bitrate: :undef, user_limit: :undef,
                               rate_limit_per_user: :undef, position: :undef, permission_overwrites: :undef,
                               parent_id: :undef, nsfw: :undef, reason: :undef, **rest)
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
          **rest
        }

        request Route[:POST, "/guilds/#{guild_id}/channels", guild_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-guild-channel-positions
      # @return [nil]
      def modify_guild_channel_positions(guild_id, channels, reason: :undef)
        request Route[:PATCH, "/guilds/#{guild_id}/channels", guild_id],
                body: channels,
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#list-active-threads
      # @return [Hash<Symbol,Object>]
      def list_active_threads(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/threads/active"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-member
      # @return [Hash<Symbol, Object>]
      def get_guild_member(guild_id, user_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/members/#{user_id}", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-preview
      # @return [Array<Hash<Symbol, Object>>]
      def list_guild_members(guild_id, limit: :undef, after: :undef, **params)
        request Route[:GET, "/guilds/#{guild_id}/members", guild_id],
                params: filter_undef({ limit: limit, after: after, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#search-guild-members
      # @return [Array<Hash<Symbol, Object>>]
      def search_guild_members(guild_id, query:, limit: :undef, **params)
        request Route[:GET, "/guilds/#{guild_id}/members/search", guild_id],
                params: filter_undef({ query: query, limit: limit, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#add-guild-member
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
      # @return [Hash<Symbol, Object>]
      def modify_guild_member(guild_id, user_id, nick: :undef, roles: :undef, mute: :undef, deaf: :undef,
                              channel_id: :undef, reason: :undef, **rest)
        data = {
          nick: nick,
          roles: roles,
          mute: mute,
          deaf: deaf,
          channel_id: channel_id,
          **rest
        }

        request Route[:PATCH, "/guilds/#{guild_id}/members/#{user_id}", guild_id],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-current-member
      # @return [Hash<Symbol, Object>]
      def modify_current_member(guild_id, nick: :undef, reason: :undef, **rest)
        request Route[:PATCH, "/guilds/#{guild_id}/members/@me", guild_id],
                body: filter_undef({ nick: nick, **rest }),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#add-guild-member-role
      # @return [nil]
      def add_guild_member_role(guild_id, user_id, role_id, reason: :undef)
        request Route[:PUT, "/guilds/#{guild_id}/members/#{user_id}/roles/#{role_id}", guild_id],
                body: '',
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#remove-guild-member-role
      # @return [nil]
      def remove_guild_member_role(guild_id, user_id, role_id, reason: :undef)
        request Route[:DELETE, "/guilds/#{guild_id}/members/#{user_id}/roles/#{role_id}", guild_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#remove-guild-member
      # @return [nil]
      def remove_guild_member(guild_id, user_id, reason: :undef)
        request Route[:DELETE, "/guilds/#{guild_id}/members/#{user_id}", guild_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-bans
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_bans(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/bans", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-ban
      # @return [Hash<Symbol, Object>]
      def get_guild_ban(guild_id, user_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/bans/#{user_id}", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#create-guild-ban
      # @return [nil]
      def create_guild_ban(guild_id, user_id, delete_message_days: :undef, reason: :undef, **rest)
        request Route[:PUT, "/guilds/#{guild_id}/bans/#{user_id}", guild_id],
                body: filter_undef({ delete_message_days: delete_message_days, **rest }),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#remove-guild-ban
      # @return [nil]
      def remove_guild_ban(guild_id, user_id, reason: :undef)
        request Route[:DELETE, "/guilds/#{guild_id}/bans/#{user_id}", guild_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-roles
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_roles(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/roles", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#create-guild-role
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
      # @return [Array<Hash<Symbol, Object>>]
      def modify_guild_role_positions(guild_id, roles, reason: :undef)
        request Route[:PATCH, "/guilds/#{guild_id}/roles", guild_id],
                body: roles,
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-guild-role
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

      # @!discord_api https://discord.com/developers/docs/resources/guild#delete-guild-role
      # @return [nil]
      def delete_guild_role(guild_id, role_id, reason: :undef)
        request Route[:DELETE, "/guilds/#{guild_id}/roles/#{role_id}", guild_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-prune-count
      # @return [Hash<Symbol, Object>]
      def get_guild_prune_count(guild_id, days: :undef, include_roles: :undef, **params)
        request Route[:GET, "/guilds/#{guild_id}/prune", guild_id],
                params: filter_undef({ days: days, include_roles: include_roles, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#begin-guild-prune
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
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_voice_regions(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/regions", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-invites
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_invites(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/invites", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-integrations
      # @return [Array<Hash<Symbol, Object>>]
      def get_guild_integrations(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/integrations", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#delete-guild-integration
      # @return [nil]
      def delete_guild_integration(guild_id, integration_id, reason: :undef)
        request Route[:DELETE, "/guilds/#{guild_id}/integrations/#{integration_id}", guild_id],
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-widget-settings
      # @return [Hash<Symbol, Object>]
      def get_guild_widget_settings(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/widget", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-guild-widget
      # @return [Hash<Symbol, Object>]
      def modify_guild_widget(guild_id, enabled: :undef, channel_id: :undef, reason: :undef, **rest)
        request Route[:PATCH, "/guilds/#{guild_id}/widget", guild_id],
                params: filter_undef({ enabled: enabled, channel_id: channel_id, **rest }),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-widget
      # @return [Hash<Symbol, Object>]
      def get_guild_widget(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/widget.json", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-vanity-url
      # @return [Hash<Symbol, Object>]
      def get_guild_vanity_url(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/vanity-url", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-widget-image
      # @return [String]
      def get_guild_widget_image(guild_id, style: :undef, **params)
        request Route[:GET, "/guilds/#{guild_id}/widget.png", guild_id],
                params: filter_undef({ style: style, **params })
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#get-guild-welcome-screen
      # @return [Hash<Symbol, Object>]
      def get_guild_welcome_screen(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/welcome-screen", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-guild-welcome-screen
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

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-current-user-voice-state
      # @return [nil]
      def modify_current_user_voice_state(guild_id, channel_id: :undef, suppress: :undef,
                                          request_to_speak_timestamp: :undef, **rest)
        data = {
          channel_id: channel_id,
          suppress: suppress,
          request_to_speak_timestamp: request_to_speak_timestamp,
          **rest
        }

        request Route[:PATCH, "/guilds/#{guild_id}/voice-states/@me", guild_id],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild#modify-user-voice-state
      # @return [nil]
      def modify_user_voice_state(guild_id, user_id, channel_id: :undef, suppress: :undef, **rest)
        data = {
          channel_id: channel_id,
          suppress: suppress,
          **rest
        }

        request Route[:PATCH, "/guilds/#{guild_id}/voice-states/#{user_id}", guild_id],
                body: filter_undef(data)
      end
    end
  end
end
