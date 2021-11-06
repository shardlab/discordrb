# frozen_string_literal: true

require 'faraday'
require 'faraday_middleware'
require 'discordrb/api/client/audit_log_endpoints'
require 'discordrb/api/client/channel_endpoints'
require 'discordrb/api/client/emoji_endpoints'
require 'discordrb/api/client/guild_endpoints'
require 'discordrb/api/client/guild_template_endpoints'
require 'discordrb/api/client/invite_endpoints'
require 'discordrb/api/client/stage_instance_endpoints'
require 'discordrb/api/client/sticker_endpoints'
require 'discordrb/api/client/user_endpoints'
require 'discordrb/api/client/voice_endpoints'
require 'discordrb/api/client/webhook_endpoints'
require 'discordrb/errors'

module Discordrb
  module API
    class Route
      # @return [String]
      attr_reader :endpoint

      # @return [Symbol]
      attr_reader :verb

      # @return [Symbol, nil]
      attr_reader :route_key

      # @return [String, nil]
      attr_reader :major_param

      # @return [String]
      attr_reader :rate_limit_key

      def initialize(verb, endpoint, major_param = nil, route_key = nil)
        @verb = verb.downcase.to_sym
        @endpoint = endpoint.delete_prefix('/')
        @route_key = route_key || endpoint.tr('/', '_').gsub(/\d+/, 'id')
        @major_param = major_param&.to_s
        @rate_limit_key = "#{@verb}:#{@route_key}:#{@major_param}"
      end

      def self.[](verb, endpoint, route_key = nil, major_param = nil)
        new(verb, endpoint, route_key, major_param)
      end

      %i[delete head get patch post put].each do |verb|
        define_method("#{verb}?") { @verb == verb }
      end
    end

    class RateLimit
      attr_reader :limit
      attr_reader :remaining
      attr_reader :reset
      attr_reader :reset_after
      attr_reader :bucket
      attr_reader :mutex

      def initialize(data = {})
        @mutex = Mutex.new
        update(data)
      end

      def update(data)
        @limit = data['x-ratelimit-limit']&.to_i || @limit || Float::INFINITY
        @remaining = data['x-ratelimit-remaining']&.to_i || @remaining || Float::INFINITY
        @reset = Time.at(data['x-ratelimit-reset']&.to_i || 0) || @reset
        @reset_after = Time.now + (data['x-ratelimit-reset-after']&.to_i || 0) || @reset_after
        @bucket = data['x-ratelimit-bucket'] || @bucket
      end
    end

    # Client for making HTTP requests to the Discord API.
    class Client
      include AuditLogEndpoints
      include ChannelEndpoints
      include EmojiEndpoints
      include GuildEndpoints
      include GuildTemplateEndpoints
      include InviteEndpoints
      include StageInstanceEndpoints
      include StickerEndpoints
      include UserEndpoints
      include VoiceEndpoints
      include WebhookEndpoints

      USER_AGENT = "DiscordBot (https://github.com/shardlab/discordrb, #{Discordrb::VERSION})"

      def initialize(token, version: 9)
        @conn = Faraday.new("https://discord.com/api/v#{version}") do |builder|
          builder.headers[:authorization] = "Bot #{token.delete_prefix('Bot ')}"
          builder.headers[:user_agent] = USER_AGENT

          builder.request :multipart
          builder.request :json

          builder.response :json, parser_options: { symbolize_names: true }

          yield(builder) if block_given?
        end

        init_rl
      end

      def raw_request(route, params: nil, body: nil, headers: {})
        trace = SecureRandom.alphanumeric(6)

        log_request(route, trace, params, body)
        resp = @conn.run_request(route.verb, route.endpoint, body, headers) do |builder|
          builder.params.update params if params
        end
        log_response(resp, trace)

        resp
      end

      def request(route, params: nil, body: nil, headers: {}, reason: nil)
        headers['X-Audit-Log-Reason'] = reason if reason && reason != :undef

        synchronize_rl_key(route.rate_limit_key) do
          response = raw_request(route, params: params, body: body, headers: headers)
          handle_response(route, response)
        end
      end

      private

      def handle_response(route, response)
        update_rate_limits(route, response)

        case response.status
        when 400
          raise Discordrb::Errors.error_class_for(response.body[:code] || 0), response.body
        when 401
          raise Discordrb::Errors::Unauthorized
        when 403
          raise Discordrb::Errors::NoPermission
        when 404
          raise Discordrb::Errors::NotFound
        when 405
          raise Discordrb::MethodNotAllowed
        when 429
          reset_time = response.headers['x-ratelimit-reset-after']
          key = route.rate_limit_key
          Discordrb::LOGGER.ratelimit("Rate limit exceeded for #{key}, resets in #{reset_time} seconds")
        else
          response.body
        end
      end

      def update_rate_limits(route, response)
        @rl_info[route.rate_limit_key] = @rl_info[response.headers['x-ratelimit-bucket']] if response.headers['x-ratelimit-bucket']
        @rl_info[route.rate_limit_key].update(response.headers)
      end

      def init_rl
        @rl_info = Hash.new { |hash, key| hash[key] = RateLimit.new }
      end

      def synchronize_rl_key(key)
        rl_info = @rl_info[key].bucket ? @rl_info[@rl_info[key].bucket] : @rl_info[key]

        rl_info.mutex.synchronize do
          sleep(rl_info.reset_after - Time.now) if (rl_info.remaining) < 1 && Time.now < rl_info.reset_after

          yield
        end
      end

      def log_request(route, trace, params, body)
        endpoint = route.endpoint + (params&.any? ? "?#{URI.encode_www_form(params)}" : '')
        Discordrb::LOGGER.info  "HTTP OUT [#{trace}] -- #{route.verb.upcase} /#{endpoint} (#{body&.length || 0})"
        Discordrb::LOGGER.debug "HTTP OUT [#{trace}] -- #{body.inspect}"
      end

      def log_response(response, trace)
        Discordrb::LOGGER.info  "HTTP IN  [#{trace}] -- #{response.status} #{response.reason_phrase}"
        Discordrb::LOGGER.debug "HTTP IN  [#{trace}] -- #{response.body.inspect}"
      end

      # @param hash [Hash<Object, Object>]
      def filter_undef(hash)
        hash.reject { |_, v| v == :undef }
      end
    end
  end
end
