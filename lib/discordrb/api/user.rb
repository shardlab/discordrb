# frozen_string_literal: true

module Discordrb::API::User
  # Cache and rate limit configurations
  CACHE_TTL = {
    user: 300,        # 5 minutes for user data
    profile: 300,     # 5 minutes for profile data
    servers: 60,      # 1 minute for server list
    connections: 300, # 5 minutes for connections
    dms: 60           # 1 minute for DM list
  }.freeze

  RATE_LIMIT = {
    requests: 50,    # Number of requests allowed
    interval: 1      # Time interval in seconds
  }.freeze

  # Initialize cache and rate limiter
  @cache = {}
  @rate_limit_timestamps = []

  module_function

  def with_rate_limit
    current_time = Time.now.to_f

    # Clean up old timestamps
    @rate_limit_timestamps.reject! { |timestamp| timestamp < current_time - RATE_LIMIT[:interval] }

    if @rate_limit_timestamps.size < RATE_LIMIT[:requests]
      @rate_limit_timestamps << current_time
      yield
    else
      sleep(1)
      retry
    end
  end

  def cached_request(cache_key, ttl)
    cached = @cache[cache_key]
    return cached[:data] if cached && cached[:expires_at] > Time.now.to_i

    response = with_rate_limit { yield }
    @cache[cache_key] = {
      data: response,
      expires_at: Time.now.to_i + ttl
    }
    response
  end

  def clear_user_cache(user_id)
    @cache.keys.each do |key|
      @cache.delete(key) if key.to_s.include?(user_id.to_s)
    end
  end

  # Enhanced API methods

  def resolve(token, user_id)
    cached_request("user:#{user_id}", CACHE_TTL[:user]) do
      Discordrb::API.request(
        :users_uid,
        nil,
        :get,
        "#{Discordrb::API.api_base}/users/#{user_id}",
        Authorization: token
      )
    end
  end

  def profile(token)
    cached_request('profile', CACHE_TTL[:profile]) do
      Discordrb::API.request(
        :users_me,
        nil,
        :get,
        "#{Discordrb::API.api_base}/users/@me",
        Authorization: token
      )
    end
  end

  def change_own_nickname(token, server_id, nick, reason = nil)
    with_rate_limit do
      response = Discordrb::API.request(
        :guilds_sid_members_me_nick,
        server_id,
        :patch,
        "#{Discordrb::API.api_base}/guilds/#{server_id}/members/@me/nick",
        { nick: nick }.to_json,
        Authorization: token,
        content_type: :json,
        'X-Audit-Log-Reason': reason
      )
      clear_user_cache('@me')
      response
    end
  end

  def update_profile(token, email, password, new_username, avatar, new_password = nil)
    with_rate_limit do
      response = Discordrb::API.request(
        :users_me,
        nil,
        :patch,
        "#{Discordrb::API.api_base}/users/@me",
        { avatar: avatar, email: email, new_password: new_password, password: password, username: new_username }.to_json,
        Authorization: token,
        content_type: :json
      )
      clear_user_cache('@me')
      response
    end
  end

  def servers(token)
    cached_request('servers', CACHE_TTL[:servers]) do
      Discordrb::API.request(
        :users_me_guilds,
        nil,
        :get,
        "#{Discordrb::API.api_base}/users/@me/guilds",
        Authorization: token
      )
    end
  end

  def leave_server(token, server_id)
    with_rate_limit do
      response = Discordrb::API.request(
        :users_me_guilds_sid,
        nil,
        :delete,
        "#{Discordrb::API.api_base}/users/@me/guilds/#{server_id}",
        Authorization: token
      )
      @cache.delete('servers')
      response
    end
  end

  def user_dms(token)
    cached_request('dms', CACHE_TTL[:dms]) do
      Discordrb::API.request(
        :users_me_channels,
        nil,
        :get,
        "#{Discordrb::API.api_base}/users/@me/channels",
        Authorization: token
      )
    end
  end

  def create_pm(token, recipient_id)
    with_rate_limit do
      response = Discordrb::API.request(
        :users_me_channels,
        nil,
        :post,
        "#{Discordrb::API.api_base}/users/@me/channels",
        { recipient_id: recipient_id }.to_json,
        Authorization: token,
        content_type: :json
      )
      @cache.delete('dms')
      response
    end
  end

  def connections(token)
    cached_request('connections', CACHE_TTL[:connections]) do
      Discordrb::API.request(
        :users_me_connections,
        nil,
        :get,
        "#{Discordrb::API.api_base}/users/@me/connections",
        Authorization: token
      )
    end
  end

  def change_status_setting(token, status)
    with_rate_limit do
      Discordrb::API.request(
        :users_me_settings,
        nil,
        :patch,
        "#{Discordrb::API.api_base}/users/@me/settings",
        { status: status }.to_json,
        Authorization: token,
        content_type: :json
      )
    end
  end

  # Cache management methods
  def clear_cache
    @cache.clear
  end

  def cache_stats
    {
      size: @cache.size,
      keys: @cache.keys,
      ttl_settings: CACHE_TTL
    }
  end

  # CDN methods (no caching needed as these are just URL generators)
  def default_avatar(discrim_id = 0, legacy: false)
    index = if legacy
              discrim_id.to_i % 5
            else
              (discrim_id.to_i >> 22) % 5
            end
    "#{Discordrb::API.cdn_url}/embed/avatars/#{index}.png"
  end

  def avatar_url(user_id, avatar_id, format = nil)
    format ||= if avatar_id.start_with?('a_')
                 'gif'
               else
                 'webp'
               end
    "#{Discordrb::API.cdn_url}/avatars/#{user_id}/#{avatar_id}.#{format}"
  end
end