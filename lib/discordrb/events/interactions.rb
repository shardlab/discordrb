# frozen_string_literal: true

require 'discordrb/events/generic'
require 'discordrb/data'

module Discordrb::Events
  # Generic subclass for interaction events
  class InteractionCreateEvent < Event
    # @return [Interaction] The interaction for this event.
    attr_reader :interaction

    # @!attribute [r] type
    #   @return [Integer]
    #   @see Interaction#type
    # @!attribute [r] server
    #   @return [Server, nil]
    #   @see Interaction#server
    # @!attribute [r] server_id
    #   @return [Integer]
    #   @see Interaction#server_id
    # @!attribute [r] channel
    #   @return [Channel]
    #   @see Interaction#channel
    # @!attribute [r] channel_id
    #   @return [Integer]
    #   @see Interaction#channel_id
    # @!attribute [r] user
    #   @return [User]
    #   @see Interaction#user
    delegate :type, :server, :server_id, :channel, :channel_id, :user, to: :interaction

    def initialize(data, bot)
      @interaction = Discordrb::Interaction.new(data, bot)
      @bot = bot
    end

    # (see Interaction#respond)
    def respond(content: nil, tts: nil, embeds: nil, allowed_mentions: nil, flags: 0, ephemeral: nil, wait: false)
      @interaction.respond(content: content, tts: tts, embeds: embeds, allowed_mentions: allowed_mentions, flags: flags, ephemeral: ephemeral, wait: wait)
    end

    # (see Interaction#defer)
    def defer(flags: 0, ephemeral: true)
      @interaction.defer(flags: flags, ephemeral: ephemeral)
    end

    # (see Interaction#edit_response)
    def edit_response(content: nil, embeds: nil, allowed_mentions: nil)
      @interaction.edit_response(content: content, embeds: embeds, allowed_mentions: allowed_mentions, &block)
    end

    # (see Interaction#delete_response)
    def delete_response
      @interaction.delete_response
    end

    # (see Interaction#send_message)
    def send_message(content: nil, embeds: nil, tts: false, allowed_mentions: nil, flags: 0, ephemeral: nil, &block)
      @interaction.send_message(content: content, embeds: embeds, tts: tts, allowed_mentions: allowed_mentions, flags: flags, ephemeral: ephemeral, &block)
    end

    # (see Interaction#edit_message)
    def edit_message(message, content: nil, embeds: nil, allowed_mentions: nil, &block)
      @interaction.edit_message(message, content: content, embeds: embeds, allowed_mentions: allowed_mentions, &block)
    end

    # (see Interaction#delete_message)
    def delete_message(message)
      @interaction.delete_message(message)
    end
  end

  # Event handler for INTERACTION_CREATE events.
  class InteractionCreateEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      return false unless event.is_a? InteractionCreateEvent

      [
        matches_all(@attributes[:type], event.type) do |a, e|
          a == case a
               when String, Symbol
                 Discordrb::Interactions::TYPES[e.to_sym]
               else
                 e
               end
        end,

        matches_all(@attributes[:server], event.interaction) do |a, e|
          a.resolve_id == e.server_id
        end,

        matches_all(@attributes[:channel], event.interaction) do |a, e|
          a.resolve_id == e.channel_id
        end,

        matches_all(@attributes[:user], event.user) do |a, e|
          a.resolve_id == e.id
        end
      ].reduce(true, &:&)
    end
  end

  # Event for ApplicationCommand interactions.
  class ApplicationCommandEvent < InteractionCreateEvent
    # @return [String] The name of the command.
    attr_reader :command_name

    # @return [Integer] The ID of the command.
    attr_reader :command_id

    # @return [String, nil] The name of the subcommand group relevant to this event.
    attr_reader :subcommand_group

    # @return [String, nil] The name of the subcommand relevant to this event.
    attr_reader :subcommand

    # @return [Hash]
    attr_reader :resolved

    # @return [Hash<Symbol, Object>] Arguments provided to the command, mapped as `Name => Value`.
    attr_reader :options

    def initialize(data, bot)
      super

      command_data = data['data']

      @command_id = command_data['id']
      @command_name = command_data['name'].to_sym

      @resolved = { users: {}, channels: {}, roles: {}, members: {} }

      process_resolved(command_data['resolved']) if command_data['resolved']

      options = command_data['options']

      if options.empty?
        @options = {}
        return
      end

      case options[0]['type']
      when 2
        options = options[0]
        @subcommand_group = options['name'].to_sym
        @subcommand = options['options'][0]['name'].to_sym
        options = options['options'][0]['options']
      when 1
        options = options[0]
        @subcommand = options['name'].to_sym
        options = options['options']
      end

      @options = transform_options_hash(options || {})
    end

    private

    def process_resolved(resolved_data)
      resolved_data['users']&.each do |id, data|
        @resolved[:users][id.to_i] = @bot.ensure_user(data)
      end

      resolved_data['roles']&.each do |id, data|
        @resolved[:roles][id.to_i] = Discordrb::Role.new(data, @bot)
      end

      resolved_data['channels']&.each do |id, data|
        data['guild_id'] = @interaction.server_id
        @resolved[:channels][id.to_i] = Discordrb::Channel.new(data, @bot)
      end

      resolved_data['members']&.each do |id, data|
        data['user'] = resolved_data['users'][id]
        @resolved[:members][id.to_i] = Discordrb::Interactions::Member.new(data, @interaction.server_id, @bot)
      end
    end

    def transform_options_hash(hash)
      hash.map { |opt| [opt['name'], opt['options'] || opt['value']] }.to_h
    end
  end

  # Event handler for ApplicationCommandEvents.
  class ApplicationCommandEventHandler < EventHandler
    # @return [Hash]
    attr_reader :subcommands

    # @!visibility private
    def initialize(attributes, block)
      super

      @subcommands = {}
    end

    # @param name [Symbol, String]
    # @yieldparam [SubcommandBuilder]
    # @return [ApplicationCommandEventHandler]
    def group(name)
      raise ArgumentError, 'Unable to mix subcommands and groups' if @subcommands.any? { |_, v| v.is_a? Proc }

      builder = SubcommandBuilder.new(name)
      yield builder

      @subcommands.merge!(builder.to_h)
      self
    end

    # @param name [String, Symbol]
    # @yieldparam [SubcommandBuilder]
    # @return [ApplicationCommandEventHandler]
    def subcommand(name, &block)
      raise ArgumentError, 'Unable to mix subcommands and groups' if @subcommands.any? { |_, v| v.is_a? Hash }

      @subcommands[name.to_sym] = block

      self
    end

    # @!visibility private
    # @param event [Event]
    def call(event)
      return unless matches?(event)

      if event.subcommand_group
        unless (cmd = @subcommands.dig(event.subcommand_group, event.subcommand))
          Discordrb::LOGGER.debug("Received an event for an unhandled subcommand `#{event.command_name} #{event.subcommand_group} #{event.subcommand}'")
          return
        end

        cmd.call(event)
      elsif event.subcommand
        unless (cmd = @subcommands[event.subcommand])
          Discordrb::LOGGER.debug("Received an event for an unhandled subcommand `#{event.command_name} #{event.subcommand}'")
          return
        end

        cmd.call(event)
      else
        @block.call(event)
      end
    end

    # @!visibility private
    def matches?(event)
      return false unless event.is_a? ApplicationCommandEvent

      [
        matches_all(@attributes[:name], event.command_name) do |a, e|
          a.to_sym == e.to_sym
        end
      ].reduce(true, &:&)
    end
  end

  # Builder for adding subcommands to an ApplicationCommandHandler
  class SubcommandBuilder
    # @!visibility private
    # @param group [String, Symbol, nil]
    def initialize(group = nil)
      @group = group&.to_sym
      @subcommands = {}
    end

    # @param name [Symbol, String]
    # @yieldparam [ApplicationCommandEvent]
    def subcommand(name, &block)
      @subcommands[name.to_sym] = block
    end

    # @!visibility private
    def to_h
      @group ? { @group => @subcommands } : @subcommands
    end
  end
end
