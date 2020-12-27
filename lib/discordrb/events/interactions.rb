# frozen_string_literal: true

require 'discordrb/webhooks'

module Discordrb::Events
  class InteractionEvent
    # @return [Integer] The interaction's ID.
    attr_reader :id

    # @return [Integer] The interaction's type (1: Ping, 2: ApplicationCommand).
    attr_reader :type

    # @return [Integer] The ID of the server where the interaction originates. 
    attr_reader :server_id

    # @return [Integer] The ID of the channel where the interaction originates.
    attr_reader :channel_id

    # @return [Member] The member that created the interaction.
    # @note Members from an interaction may not support all methods if
    #   the application has not been granted the `bot` scope for the server.
    attr_reader :author

    # @return [String] A continuation token for responding to the interaction.
    attr_reader :token

    # @return [Integer] Always `1`.
    attr_reader :version

    # @return [Hash]
    # @note Only useful for ApplicationCommand types currently, exposed for use
    #   with future interaction types.
    attr_reader :data

    # @return [Discordrb::Webhooks::Client]
    attr_reader :webhook

    def initialize(data, bot)
      @bot = bot

      @id = data['id'].to_i
      @type = data['type']
      @server_id = data['guild_id'].to_i
      @channel_id = data['channel_id'].to_i
      @author = Discordrb::Member.new(data['member'], @bot.server(@server_id), @bot)
      @token = data['token']
      @version = data['version']
      @data = data['data']
      @application_id = @bot.client_id
    
      @webhook = Discordrb::Webhooks::Client.new(id: @application_id, token: @token)
    end

    def server
      @bot.server(@server_id)
    end

    def channel
      @bot.channel(@channel_id)
    end

    def ephemeral_reply(content, show_source: false)
      reply(content: content, show_source: show_source, flags: 1 << 6)
    end

    def reply(content: nil, tts: nil, embeds: nil, allowed_mentions: nil, show_source: false, flags: nil)
      Discordrb::API::Webhook.create_interaction_response(@token, @id, show_source ? 4 : 3, content: content, embeds: embeds, allowed_mentions: allowed_mentions, flags: flags)
    end

    def acknowledge(show_source: false)
      Discordrb::API::Webhook.create_interaction_response(@token, @id, show_source ? 5 : 2)
    end

    def edit_original_response(content: nil, embeds: nil, allowed_mentions: nil)
      Discordrb::API::Webhook.edit_original_interaction_response(@token, @application_id, content: content, embeds: embeds, allowed_mentions: allowed_mentions)
    end

    def edit_message(message_id, content: nil, embeds: nil, allowed_mentions: nil)
      Discordrb::API::Webhook.edit_webhook_message(@token, @application_id, message_id, content: content, embeds: embed, allowed_mentions: allowed_mentions)
    end

    def delete_message(message_id)
      Discordrb::API::Webhook.delete_webhook_message(@token, @application_id, message_id)
    end

    def delete_original_response
      Discordrb::API::Webhook.delete_original_interaction_response(@token, @application_id)
    end
  end

  class InteractionEventHandler < EventHandler
    def matches?(event)
      return false unless event.is_a? InteractionEvent

      [
        matches_all(@attributes[:server], event.server_id) do |a, e|
          a.id == e
        end,
        matches_all(@attributes[:channel], event.channel_id) do |a, e|
          a.id == e
        end,
        matches_all(@attributes[:type], event.type, &:==)
      ].reduce(true, &:&)
    end
  end

  class ApplicationCommandEvent < InteractionEvent
    # @return [String, nil]
    attr_reader :subcommand

    # @return [String, nil]
    attr_reader :subcommand_group
    
    # @return [Hash<String, Object>]
    attr_reader :options

    attr_reader :command_name

    def initialize(data, bot)
      super

      @command_name = data['data']['name']
      options = data['data']['options']

      if !options[0].key?('value')
        @subcommand = options[0]['name']
        options = options[0]['options'] || []

        if options[0].is_a?(Hash) && !options[0].key?('value')
          @subcommand_group = @subcommand
          @subcommand = options[0]['name']

          options = options[0]['options'] || []
        end
      end

      @options = options.map { |opt| [opt['name'], opt['value']] }.to_h
    end
  end

  class ApplicationCommandEventHandler < InteractionEventHandler
    def matches?(event)
      return false unless event.is_a? ApplicationCommandEvent

      [
        super,
        matches_all(@attributes[:command_name], event.command_name) do |a, e|
          a.to_s == e
        end,
        matches_all(@attributes[:group], event.subcommand_group) do |a, e|
          a.to_s == e
        end,
        matches_all(@attributes[:subcommand], event.subcommand) do |a, e|
          a.to_s == e
        end
      ].reduce(true, &:&)
    end
  end
end
