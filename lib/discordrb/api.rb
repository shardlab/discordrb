# frozen_string_literal: true

require 'json'
require 'time'

require 'discordrb/errors'

# List of methods representing endpoints in Discord's API
module Discordrb::API

  # The URL of Discord's CDN
  CDN_URL = 'https://cdn.discordapp.com'

  module_function

  # @return [String] the currently used CDN url
  def cdn_url
    @cdn_url || CDN_URL
  end

  # Make an icon URL from server and icon IDs
  def icon_url(server_id, icon_id, format = 'webp')
    "#{cdn_url}/icons/#{server_id}/#{icon_id}.#{format}"
  end

  # Make an icon URL from application and icon IDs
  def app_icon_url(app_id, icon_id, format = 'webp')
    "#{cdn_url}/app-icons/#{app_id}/#{icon_id}.#{format}"
  end

  # Make a widget picture URL from server ID
  def widget_url(server_id, style = 'shield')
    "#{api_base}/guilds/#{server_id}/widget.png?style=#{style}"
  end

  # Make a splash URL from server and splash IDs
  def splash_url(server_id, splash_id, format = 'webp')
    "#{cdn_url}/splashes/#{server_id}/#{splash_id}.#{format}"
  end

  # Make a banner URL from server and banner IDs
  def banner_url(server_id, banner_id, format = 'webp')
    "#{cdn_url}/banners/#{server_id}/#{banner_id}.#{format}"
  end

  # Make an emoji icon URL from emoji ID
  def emoji_icon_url(emoji_id, format = 'webp')
    "#{cdn_url}/emojis/#{emoji_id}.#{format}"
  end

  # Make an asset URL from application and asset IDs
  def asset_url(application_id, asset_id, format = 'webp')
    "#{cdn_url}/app-assets/#{application_id}/#{asset_id}.#{format}"
  end

  # Make an achievement icon URL from application ID, achievement ID, and icon hash
  def achievement_icon_url(application_id, achievement_id, icon_hash, format = 'webp')
    "#{cdn_url}/app-assets/#{application_id}/achievements/#{achievement_id}/icons/#{icon_hash}.#{format}"
  end

  # Make a role icon URL from role ID and icon hash
  def role_icon_url(role_id, icon_hash, format = 'webp')
    "#{cdn_url}/role-icons/#{role_id}/#{icon_hash}.#{format}"
  end

  # Make one of the "default" discord avatars from the CDN given a discriminator
  def default_avatar(discrim = 0)
    index = discrim.to_i % 5
    "#{Discordrb::API.cdn_url}/embed/avatars/#{index}.png"
  end

  # Make an avatar URL from the user ID and avatar ID
  def avatar_url(user_id, avatar_id, format = nil)
        format ||= if avatar_id.start_with?('a_')
                 'gif'
               else
                 'webp'
               end
    "#{cdn_url}/embed/avatars/#{user_id}/#{avatar_id}.#{format}"
  end

  # Create an OAuth application
  def create_oauth_application(token, name, redirect_uris)
    request(
      :oauth2_applications,
      nil,
      :post,
      "#{api_base}/oauth2/applications",
      { name: name, redirect_uris: redirect_uris }.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Change an OAuth application's properties
  def update_oauth_application(token, name, redirect_uris, description = '', icon = nil)
    request(
      :oauth2_applications,
      nil,
      :put,
      "#{api_base}/oauth2/applications",
      { name: name, redirect_uris: redirect_uris, description: description, icon: icon }.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Get the bot's OAuth application's information
  def oauth_application(token)
    request(
      :oauth2_applications_me,
      nil,
      :get,
      "#{api_base}/oauth2/applications/@me",
      Authorization: token
    )
  end
