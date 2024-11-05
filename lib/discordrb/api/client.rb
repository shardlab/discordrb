# frozen_string_literal: true

require 'faraday'
require 'faraday/multipart'
require 'discordrb/api/endpoints/application_command'
require 'discordrb/api/endpoints/application'
require 'discordrb/api/endpoints/audit_log'
require 'discordrb/api/endpoints/auto_moderation'
require 'discordrb/api/endpoints/channel'
require 'discordrb/api/endpoints/emoji'
require 'discordrb/api/endpoints/entitlement'
require 'discordrb/api/endpoints/guild_scheduled_event'
require 'discordrb/api/endpoints/guild'
require 'discordrb/api/endpoints/guild_template'
require 'discordrb/api/endpoints/interaction'
require 'discordrb/api/endpoints/invite'
require 'discordrb/api/endpoints/message'
require 'discordrb/api/endpoints/poll'
require 'discordrb/api/endpoints/sku'
require 'discordrb/api/endpoints/soundboard'
require 'discordrb/api/endpoints/stage_instance'
require 'discordrb/api/endpoints/sticker'
require 'discordrb/api/endpoints/user'
require 'discordrb/api/endpoints/voice'
require 'discordrb/api/endpoints/webhook'
require 'discordrb/errors'

module Discordrb
  module API
    # @!api private
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

      # @param verb [Symbol]
      # @param endpoint [String]
      # @param major_param [#to_s, nil]
      # @param route_key [String, nil]
      def initialize(verb, endpoint, major_param = nil, route_key = nil)
        @verb = verb.downcase.to_sym
        @endpoint = endpoint.delete_prefix('/')
        @route_key = route_key || endpoint.delete_prefix('/').tr('/', '_').gsub(/\d+/, 'id')
        @major_param = major_param&.to_s
        @rate_limit_key = "#{@verb}:#{@route_key}:#{@major_param}"
      end

      # @param verb [Symbol]
      # @param endpoint [String]
      # @param major_param [String, nil]
      # @param route_key [String, nil]
      def self.[](verb, endpoint, major_param = nil, route_key = nil)
        new(verb, endpoint, major_param, route_key)
      end

      %i[delete head get patch post put].each do |verb|
        define_method("#{verb}?") { @verb == verb }
      end
    end

    # @!api private
    class RateLimit
      # @return [Integer, nil]
      attr_reader :limit

      # @return [Integer, nil]
      attr_reader :remaining

      # @return [Time, nil]
      attr_reader :reset

      # @return [Time, nil]
      attr_reader :reset_after

      # @return [String, nil]
      attr_reader :bucket

      # @return [Mutex]
      attr_reader :mutex

      def initialize(data = {})
        @mutex = Mutex.new
        update(data)
      end

      # @param data [Hash]
      def update(data)
        @limit = data['x-ratelimit-limit'].to_i || @limit || Float::INFINITY
        @remaining = data['x-ratelimit-remaining'].to_i || @remaining || Float::INFINITY
        @reset = Time.at(data['x-ratelimit-reset'].to_i) || @reset
        @reset_after = (Time.now + data['x-ratelimit-reset-after'].to_f) || @reset_after
        @bucket = data['x-ratelimit-bucket'] || @bucket
      end
    end

    # Client for making HTTP requests to the Discord API.
    class Client
      include ApplicationCommandEndpoints
      include ApplicationEndpoints
      include AuditLogEndpoints
      include AutoModerationEndpoints
      include ChannelEndpoints
      include EmojiEndpoints
      include EntitlementEndpoints
      include GuildScheduledEventEndpoints
      include GuildEndpoints
      include GuildTemplateEndpoints
      include InteractionEndpoints
      include InviteEndpoints
      include MessageEndpoints
      include PollEndpoints
      include SkuEndpoints
      include SoundboardEndpoints
      include StageInstanceEndpoints
      include StickerEndpoints
      include UserEndpoints
      include VoiceEndpoints
      include WebhookEndpoints

      # The user agent used when making requests.
      USER_AGENT = "DiscordBot (https://github.com/shardlab/discordrb, #{Discordrb::VERSION})".freeze

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

      def get_gateway_bot(**params)
        request Route[:GET, '/gateway/bot'],
                params: filter_undef(params)
      end

      private

      # @param route [Route]
      # @param params [Hash, nil]
      # @param body [Hash, nil]
      # @param headers [Hash]
      def raw_request(route, params: nil, body: nil, headers: {})
        trace = SecureRandom.alphanumeric(6)

        log_request(route, trace, params, body)
        resp = @conn.run_request(route.verb, route.endpoint, body, headers) do |builder|
          builder.params.update params if params
        end
        log_response(resp, trace)

        resp
      end

      # @param route [Route]
      # @param params [Hash, nil]
      # @param body [Hash, nil]
      # @param headers [Hash, nil]
      # @param reason [String, nil]
      def request(route, params: nil, body: nil, headers: {}, reason: nil)
        headers['X-Audit-Log-Reason'] = reason if reason && reason != :undef

        synchronize_rl_key(route.rate_limit_key) do
          response = raw_request(route, params: params, body: body, headers: headers)
          handle_response(route, response)
        end
      end

      # @param route [Route]
      # @param response [Faraday::Response]
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

      # @param route [Route]
      # @param response [Faraday::Response]
      def update_rate_limits(route, response)
        @rl_info[route.rate_limit_key] = @rl_info[response.headers['x-ratelimit-bucket']] if response.headers['x-ratelimit-bucket']
        @rl_info[route.rate_limit_key].update(response.headers)
      end

      def init_rl
        @rl_info = Hash.new { |hash, key| hash[key] = RateLimit.new }
      end

      # @param key [String]
      def synchronize_rl_key(key)
        rl_info = @rl_info[key].bucket ? @rl_info[@rl_info[key].bucket] : @rl_info[key]

        rl_info.mutex.synchronize do
          if (rl_info.remaining) < 1 && Time.now < rl_info.reset_after
            duration = rl_info.reset_after - Time.now

            LOGGER.ratelimit("Preemptively locking #{key} for #{duration} seconds")
            sleep(duration)
          end

          yield
        end
      end

      # @param route [Route]
      # @param trace [String]
      # @param params [Hash, nil]
      # @param body [Object, nil]
      def log_request(route, trace, params = nil, body = nil)
        endpoint = route.endpoint
        endpoint += "?#{URI.encode_www_form(params || {})}" if params&.any?

        Discordrb::LOGGER.info  "HTTP OUT [#{trace}] -- #{route.verb.upcase} /#{endpoint}"
        Discordrb::LOGGER.debug "HTTP OUT [#{trace}] -- Request Body: #{body.inspect}" if body
      end

      # @param response [Faraday::Response]
      # @param trace [String]
      def log_response(response, trace)
        Discordrb::LOGGER.info  "HTTP IN  [#{trace}] -- #{response.status} #{response.reason_phrase}"
        Discordrb::LOGGER.debug "HTTP IN  [#{trace}] -- Response Body: #{response.body.inspect}"
      end

      # @param hash [Hash<Object, Object>]
      def filter_undef(hash)
        hash.reject { |_, v| v == :undef }
      end
    end
  end
end
