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
    # @!attribute [r] channel
    #   @return [Channel, nil]
    #   @see Interaction#channel
    # @!attribute [r] user
    #   @return [User]
    #   @see Interaction#user
    delegate :type, :server, :channel, :user, to: :interaction

    def initialize(data, bot)
      @interaction = Discordrb::Interaction.new(data, bot)
      @bot = bot
    end

    # (see Interaction#respond)
    def respond(content: nil, tts: nil, embeds: nil, allowed_mentions: nil, flags: 0, ephemeral: nil)
      @interaction.respond(content: content, tts: tts, embeds: embeds, allowed_mentions: allowed_mentions, flags: flags, ephemeral: ephemeral)
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
end
