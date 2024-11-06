# frozen_string_literal: true

require 'discordrb/api'
require 'discordrb/api/server'
require 'discordrb/api/invite'
require 'discordrb/api/user'
require 'discordrb/data'
require 'concurrent-ruby'

module Discordrb
  module Cache
    CACHE_TTL = {
      user: 300,        # 5 minutes
      server: 600,      # 10 minutes
      channel: 300,     # 5 minutes
      voice_region: 3600, # 1 hour
      invite: 60        # 1 minute
    }.freeze

    RATE_LIMIT = {
      requests: 50,    # Number of requests allowed
      interval: 1      # Time interval in seconds
    }.freeze

    def init_cache
      @cache = Concurrent::Map.new
      @rate_limiter = Concurrent::RateMonitor.new(RATE_LIMIT[:requests], RATE_LIMIT[:interval])
    end

    def with_rate_limit
      @rate_limiter.wait
      yield
    rescue Concurrent::RateLimitExceeded
      sleep(1)
      retry
    end

    def cached_request(key, ttl)
      cached = @cache[key]
      return cached[:data] if cached && cached[:expires_at] > Time.now.to_i

      response = with_rate_limit { yield }
      @cache[key] = {
        data: response,
        expires_at: Time.now.to_i + ttl
      }
      response
    end

    def voice_regions
      cached_request('voice_regions', CACHE_TTL[:voice_region]) do
        regions = JSON.parse API.voice_regions(token)
        regions.map { |data| VoiceRegion.new(data) }
      end
    end

    def channel(id, server = nil)
      id = id.resolve_id
      cached_request("channel:#{id}", CACHE_TTL[:channel]) do
        begin
          response = API::Channel.resolve(token, id)
          Channel.new(JSON.parse(response), self, server)
        rescue Discordrb::Errors::UnknownChannel
          nil
        end
      end
    end

    alias_method :group_channel, :channel

    def user(id)
      id = id.resolve_id
      cached_request("user:#{id}", CACHE_TTL[:user]) do
        begin
          response = API::User.resolve(token, id)
          User.new(JSON.parse(response), self)
        rescue Discordrb::Errors::UnknownUser
          nil
        end
      end
    end

    def server(id)
      id = id.resolve_id
      cached_request("server:#{id}", CACHE_TTL[:server]) do
        begin
          response = API::Server.resolve(token, id)
          Server.new(JSON.parse(response), self)
        rescue Discordrb::Errors::NoPermission
          nil
        end
      end
    end

    def member(server_or_id, user_id)
      server_id = server_or_id.resolve_id
      user_id = user_id.resolve_id
      server = server_or_id.is_a?(Server) ? server_or_id : self.server(server_id)

      cached_request("member:#{server_id}:#{user_id}", CACHE_TTL[:user]) do
        begin
          response = API::Server.resolve_member(token, server_id, user_id)
          Member.new(JSON.parse(response), server, self)
        rescue Discordrb::Errors::UnknownUser, Discordrb::Errors::UnknownMember
          nil
        end
      end
    end

    def pm_channel(id)
      id = id.resolve_id
      cached_request("pm_channel:#{id}", CACHE_TTL[:channel]) do
        response = API::User.create_pm(token, id)
        Channel.new(JSON.parse(response), self)
      end
    end

    alias_method :private_channel, :pm_channel

    def ensure_user(data)
      user_id = data['id'].to_i
      cached_request("user:#{user_id}", CACHE_TTL[:user]) do
        User.new(data, self)
      end
    end

    def ensure_server(data, force_cache = false)
      server_id = data['id'].to_i
      cached_request("server:#{server_id}", CACHE_TTL[:server]) do
        Server.new(data, self)
      end
    end

    def ensure_channel(data, server = nil)
      channel_id = data['id'].to_i
      cached_request("channel:#{channel_id}", CACHE_TTL[:channel]) do
        Channel.new(data, self, server)
      end
    end

    def ensure_thread_member(data)
      thread_id = data['id'].to_i
      user_id = data['user_id'].to_i
      key = "thread_member:#{thread_id}:#{user_id}"

      @cache[key] = {
        data: data.slice('join_timestamp', 'flags'),
        expires_at: Time.now.to_i + CACHE_TTL[:user]
      }
    end

    def request_chunks(id)
      with_rate_limit do
        @gateway.send_request_members(id, '', 0)
      end
    end

    def resolve_invite_code(invite)
      invite = invite.code if invite.is_a? Discordrb::Invite
      invite = invite[invite.rindex('/') + 1..] if invite.start_with?('http', 'discord.gg')
      invite
    end

    def invite(invite)
      code = resolve_invite_code(invite)
      cached_request("invite:#{code}", CACHE_TTL[:invite]) do
        Invite.new(JSON.parse(API::Invite.resolve(token, code)), self)
      end
    end

    def find_channel(channel_name, server_name = nil, type: nil)
      results = []

      if /<#(?<id>\d+)>?/ =~ channel_name
        return [channel(id)]
      end

      @cache.each_pair do |key, value|
        next unless key.start_with?('server:')
        server = value[:data]
        server.channels.each do |channel|
          results << channel if channel.name == channel_name && (server_name || server.name) == server.name && (!type || (channel.type == type))
        end
      end

      results
    end

    def find_user(username, discrim = nil)
      users = @cache.select { |k, v| k.start_with?('user:') && v[:data].username == username }.values.map { |v| v[:data] }
      return users.find { |u| u.discrim == discrim } if discrim

      users
    end

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
  end
end