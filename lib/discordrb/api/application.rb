# frozen_string_literal: true

require 'concurrent-ruby'

module Discordrb::API::Application
  # Cache configuration
  CACHE_TTL = 300 # 5 minutes cache duration
  RATE_LIMIT_REQUESTS = 50 # Number of requests allowed
  RATE_LIMIT_INTERVAL = 1 # Time interval in seconds

  # Initialize cache and rate limiter
  @cache = Concurrent::Map.new
  @rate_limiter = Concurrent::RateMonitor.new(RATE_LIMIT_REQUESTS, RATE_LIMIT_INTERVAL)

  module_function

  def with_rate_limit
    @rate_limiter.wait
    yield
  rescue Concurrent::RateLimitExceeded
    sleep(1) # Wait if rate limit is exceeded
    retry
  end

  def cache_key(*args)
    args.join(':')
  end

  def cached_request(cache_key, ttl = CACHE_TTL)
    cached = @cache[cache_key]
    return cached if cached && cached[:expires_at] > Time.now.to_i

    response = with_rate_limit { yield }
    @cache[cache_key] = {
      data: response,
      expires_at: Time.now.to_i + ttl
    }
    response
  end

  # Modified API methods with caching and rate limiting

  def get_global_commands(token, application_id)
    key = cache_key('global_commands', application_id)
    cached_request(key) do
      Discordrb::API.request(
        :applications_aid_commands,
        nil,
        :get,
        "#{Discordrb::API.api_base}/applications/#{application_id}/commands",
        Authorization: token
      )
    end
  end

  def get_global_command(token, application_id, command_id)
    key = cache_key('global_command', application_id, command_id)
    cached_request(key) do
      Discordrb::API.request(
        :applications_aid_commands_cid,
        nil,
        :get,
        "#{Discordrb::API.api_base}/applications/#{application_id}/commands/#{command_id}",
        Authorization: token
      )
    end
  end

  def create_global_command(token, application_id, name, description, options = [], default_permission = nil, type = 1, default_member_permissions = nil, contexts = nil)
    with_rate_limit do
      response = Discordrb::API.request(
        :applications_aid_commands,
        nil,
        :post,
        "#{Discordrb::API.api_base}/applications/#{application_id}/commands",
        { name: name, description: description, options: options, default_permission: default_permission, type: type, default_member_permissions: default_member_permissions, contexts: contexts }.to_json,
        Authorization: token,
        content_type: :json
      )
      
      # Invalidate related caches
      @cache.delete(cache_key('global_commands', application_id))
      response
    end
  end

  # Add similar modifications to other methods...
  # Example for edit_global_command:
  def edit_global_command(token, application_id, command_id, name = nil, description = nil, options = nil, default_permission = nil, type = 1, default_member_permissions = nil, contexts = nil)
    with_rate_limit do
      response = Discordrb::API.request(
        :applications_aid_commands_cid,
        nil,
        :patch,
        "#{Discordrb::API.api_base}/applications/#{application_id}/commands/#{command_id}",
        { name: name, description: description, options: options, default_permission: default_permission, type: type, default_member_permissions: default_member_permissions, contexts: contexts }.compact.to_json,
        Authorization: token,
        content_type: :json
      )
      
      # Invalidate related caches
      @cache.delete(cache_key('global_commands', application_id))
      @cache.delete(cache_key('global_command', application_id, command_id))
      response
    end
  end

  # Helper method to clear cache
  def clear_cache
    @cache.clear
  end

  # Helper method to get cache statistics
  def cache_stats
    {
      size: @cache.size,
      keys: @cache.keys
    }
  end
end