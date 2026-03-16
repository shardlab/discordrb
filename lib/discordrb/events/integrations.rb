# frozen_string_literal: true

require 'discordrb/data'
require 'discordrb/events/generic'

module Discordrb::Events
  # Generic superclass for integration events.
  class IntegrationEvent < Event
    # @return [Server] the server associated with the event.
    attr_reader :server

    # @return [Integration] the integration associated with the event.
    attr_reader :integration

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @server = bot.server(data['guild_id'].to_i)
      @integration = Discordrb::Integration.new(data, @bot, @server)
    end
  end

  # Raised whenever an integration is created.
  class IntegrationCreateEvent < IntegrationEvent; end

  # Raised whenever an integration is updated.
  class IntegrationUpdateEvent < IntegrationEvent; end

  # Raised whenever an integration is deleted.
  class IntegrationDeleteEvent < Event
    # @return [Server] the server associated with the event.
    attr_reader :server

    # @return [Integer] the ID of the integration that was removed.
    attr_reader :integration_id

    # @return [Integer, nil] the ID of the application that was removed.
    attr_reader :application_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @server = bot.server(data['guild_id'].to_i)
      @integration_id = data['id'].to_i
      @application_id = data['application_id']&.to_i
    end
  end

  # Generic event handler for integration events.
  class IntegrationEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(IntegrationEvent)

      [
        matches_all(@attributes[:server], event.server) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:id], event.integration) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:application], event.integration) do |a, e|
          a&.resolve_id == e.application&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for INTEGRATION_CREATE events.
  class IntegrationCreateEventHandler < IntegrationEventHandler; end

  # Event handler for INTEGRATION_UPDATE events.
  class IntegrationUpdateEventHandler < IntegrationEventHandler; end

  # Event handler for INTEGRATION_DELETE events.
  class IntegrationDeleteEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(IntegrationDeleteEvent)

      [
        matches_all(@attributes[:server], event.server) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:id], event.integration_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:application], event.application_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end
end
