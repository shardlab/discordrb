# frozen_string_literal: true

require 'json'
require 'time'

require 'discordrb/errors'

# List of methods representing endpoints in Discord's API
module Discordrb::API
  # The base URL of the Discord REST API.
  APIBASE = 'https://discord.com/api/v9'

  # The URL of Discord's CDN
  CDN_URL = 'https://cdn.discordapp.com'

  module_function

  # @return [String] the currently used API base URL.
  def api_base
    @api_base || APIBASE
  end

  # @return [String] the currently used CDN url
  def cdn_url
    @cdn_url || CDN_URL
  end

  # Changes the rate limit tracing behaviour. If rate limit tracing is on, a full backtrace will be logged on every RL
  # hit.
  # @param value [true, false] whether or not to enable rate limit tracing
  def trace=(value)
    @trace = value
  end

  # Resets all rate limit mutexes
  def reset_mutexes
    @mutexes = {}
    @global_mutex = Mutex.new
  end

  # Wait a specified amount of time synchronised with the specified mutex.
  def sync_wait(time, mutex)
    mutex.synchronize { sleep time }
  end

  # Wait for a specified mutex to unlock and do nothing with it afterwards.
  def mutex_wait(mutex)
    mutex.lock
    mutex.unlock
  end

  # Handles pre-emptive rate limiting by waiting the given mutex by the difference of the Date header to the
  # X-Ratelimit-Reset header, thus making sure we don't get 429'd in any subsequent requests.
  def handle_preemptive_rl(headers, mutex, key)
    Discordrb::LOGGER.ratelimit "RL bucket depletion detected! Date: #{headers[:date]} Reset: #{headers[:x_ratelimit_reset]}"
    delta = headers[:x_ratelimit_reset_after].to_f
    Discordrb::LOGGER.warn("Locking RL mutex (key: #{key}) for #{delta} seconds pre-emptively")
    sync_wait(delta, mutex)
  end

  # Perform rate limit tracing. All this method does is log the current backtrace to the console with the `:ratelimit`
  # level.
  # @param reason [String] the reason to include with the backtrace.
  def trace(reason)
    unless @trace
      Discordrb::LOGGER.debug("trace was called with reason #{reason}, but tracing is not enabled")
      return
    end

    Discordrb::LOGGER.ratelimit("Trace (#{reason}):")

    caller.each do |str|
      Discordrb::LOGGER.ratelimit(" #{str}")
    end
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

  # Get the gateway to be used, with additional information for sharding and
  # session start limits
  def gateway_bot(token)
    request(
      :gateway_bot,
      nil,
      :get,
      "#{api_base}/gateway/bot",
      Authorization: token
    )
  end

Discordrb::API.reset_mutexes
