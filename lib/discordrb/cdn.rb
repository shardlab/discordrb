# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/reference#image-formatting
    module CDN
      # The URL of Discord's CDN.
      CDN_URL = 'https://cdn.discordapp.com'

      module_function

      # the currently used CDN url.
      # @return [String]
      def cdn_url
        CDN_URL
      end

      # Make an emoji icon URL from emoji ID.
      # @return [String]
      def emoji_icon_url(emoji_id, format = 'webp')
        "#{cdn_url}/emojis/#{emoji_id}.#{format}"
      end

      # Make an icon URL from server and icon IDs.
      # @return [String]
      def icon_url(server_id, icon_id, format = 'webp')
        "#{cdn_url}/icons/#{server_id}/#{icon_id}.#{format}"
      end

      # Make a splash URL from server and splash IDs.
      # @return [String]
      def splash_url(server_id, splash_id, format = 'webp')
        "#{cdn_url}/splashes/#{server_id}/#{splash_id}.#{format}"
      end

      # Make a discovery splash URL from server and splash IDs.
      # @return [String]
      def discovery_splash_url(server_id, discovery_splash_id, format = 'webp')
        "#{cdn_url}/discovery-splashes/#{server_id}/#{discovery_splash_id}.#{format}"
      end

      # Make a banner URL from server and banner IDs.
      # @return [String]
      def banner_url(server_id, banner_id, format = 'webp')
        "#{cdn_url}/banners/#{server_id}/#{banner_id}.#{format}"
      end

      # Make a user banner URL from user and banner hash.
      # @return [String]
      def user_banner_url(user_id, banner_hash, format = 'webp')
        "#{cdn_url}/banners/#{user_id}/#{banner_hash}.#{format}"
      end

      # Make one of the "default" discord avatars given a discriminator or user ID.
      # @return [String]
      def default_avatar(discrim = 0, user_id: nil)
        index = if discrim != 0
                  discrim.to_i % 5
                elsif user_id
                  (user_id >> 22) % 5
                else
                  0
                end
        "#{cdn_url}/embed/avatars/#{index}.png"
      end

      # Make a user avatar URL from the user ID and avatar ID.
      # @return [String]
      def avatar_url(user_id, avatar_id, format = nil)
        format ||= if avatar_id.start_with?('a_')
                     'gif'
                   else
                     'webp'
                   end
        "#{cdn_url}/embed/avatars/#{user_id}/#{avatar_id}.#{format}"
      end

      # Make a guild member avatar URL from the user ID, guild ID, and avatar ID.
      # @return [String]
      def guild_avatar_url(user_id, guild_id, avatar_id, format = nil)
        format ||= if avatar_id.start_with?('a_')
                     'gif'
                   else
                     'webp'
                   end
        "#{cdn_url}/guilds/#{guild_id}/users/#{user_id}/avatars/#{avatar_id}.#{format}"
      end

      # Make an avatar decoration URL from avatar decoration hash.
      # @return [String]
      def avatar_decoration_url(decoration_hash)
        "#{cdn_url}/avatar-decoration-presets/#{decoration_hash}/.png"
      end

      # Make an icon URL from application and icon IDs.
      # @return [String]
      def app_icon_url(app_id, icon_id, format = 'webp')
        "#{cdn_url}/app-icons/#{app_id}/#{icon_id}.#{format}"
      end

      # Make an icon URL from application and icon IDs.
      # @return [String]
      def app_icon_cover(app_id, cover_id, format = 'webp')
        "#{cdn_url}/app-icons/#{app_id}/#{cover_id}.#{format}"
      end

      # Make an asset URL from application and asset IDs.
      # @return [String]
      def asset_url(application_id, asset_id, format = 'webp')
        "#{cdn_url}/app-assets/#{application_id}/#{asset_id}.#{format}"
      end

      # Make a sticker pack banner given the banner ID.
      # @return [String]
      def sticker_pack_banner_url(banner_id, format = 'webp')
        "#{cdn_url}/app-assets/710982414301790216/store#{banner_id}.#{format}"
      end

      # Make a team icon URL given the team ID and icon hash.
      # @return [String]
      def team_icon(team_id, icon_hash, format = 'webp')
        "#{cdn_url}/team-icons/#{team_id}/#{icon_hash}.#{format}"
      end

      # Make a sticker URL given the sticker ID.
      # @return [String]
      def sticker_url(sticker_id, format = 'png')
        "https://media.discordapp.net/stickers/#{sticker_id}.#{format}"
      end

      # Make a role icon URL from role ID and icon hash.
      # @return [String]
      def role_icon_url(role_id, icon_hash, format = 'webp')
        "#{cdn_url}/role-icons/#{role_id}/#{icon_hash}.#{format}"
      end

      # Make a scheduled event cover given the event ID and cover image hash.
      # @return [String]
      def guild_scheduled_event_cover(scheduled_event_id, cover_image_hash, format = 'webp')
        "#{cdn_ur}/guild-events/#{scheduled_event_id}/#{cover_image_hash}.#{format}"
      end

      # Make a guild member banner URL from user ID, guild ID, and banner hash.
      # @return [String]
      def guild_user_banner_url(guild_id, user_id, banner_hash, format = 'webp')
        "#{cdn_url}/guilds/#{guild_id}/users/#{user_id}/banners/#{banner_hash}.#{format}"
      end

      # Make a widget picture URL from server ID.
      # @return [String]
      def widget_url(server_id, style = 'shield')
        "#{api_base}/guilds/#{server_id}/widget.png?style=#{style}"
      end
    end
  end
end
