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

module Discordrb
  module API
    class Route
      # @return [String]
      attr_reader :endpoint

      # @return [Symbol]
      attr_reader :verb

      # @return [Symbol, nil]
      attr_reader :route_key

      # @return
      attr_reader :major_param

      def initialize(verb, endpoint, major_param = nil, route_key = nil)
        @verb = verb.downcase.to_sym
        @endpoint = endpoint.delete_prefix('/')
        @route_key = route_key || endpoint.tr('/', '_')
        @major_param = major_param
        @rate_limit_key = "#{@verb}:#{@route_key}:#{@major_param}"
      end

      def self.[](verb, endpoint, route_key = nil, major_param = nil)
        new(verb, endpoint, route_key, major_param)
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

      DEFAULT_UA = "DiscordBot (https://github.com/shardlab/discordrb, #{Discordrb::VERSION})"

      def initialize(token, user_agent: nil, version: 9)
        @conn = Faraday.new("https://discord.com/api/v#{version}") do |builder|
          builder.headers[:authorization] = "Bot #{token.delete_prefix('Bot ')}"
          builder.headers[:user_agent] = user_agent || DEFAULT_UA

          builder.request :multipart
          builder.request :json

          builder.response :json, parser_options: { symbolize_names: true }

          yield(builder) if block_given?
        end
      end

      def raw_request(route, params: nil, body: nil, headers: {})
        @conn.run_request(route.verb, route.endpoint, body, headers) do |builder|
          builder.params.update params if params
        end
      end

      def request(route, params: nil, body: nil, headers: {}, reason: nil)
        headers['X-Audit-Log-Reason'] = reason if reason && reason != :undef
        response = raw_request(route, params: params, body: body, headers: headers)

        update_rate_limits(response)

        response.body
      end

      def get_guild(guild_id)
        request Route[:GET, "/guilds/#{guild_id}", guild_id]
      end


      private

      def update_rate_limits(_response)
        nil
      end

      # @param hash [Hash<Object, Object>]
      def filter_undef(hash)
        hash.reject { |_, v| v == :undef }
      end
    end
  end
end
