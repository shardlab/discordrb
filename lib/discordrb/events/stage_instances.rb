# frozen_string_literal: true

module Discordrb::Events
  # Generic superclass for stage instance events.
  class StageInstanceEvent < Event
    # @return [Channel] the channel of the stage instance.
    attr_reader :channel

    # @return [StageInstance] the stage instance in question.
    attr_reader :stage_instance

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @channel = bot.channel(data['channel_id'].to_i)
      @stage_instance = @channel.stage_instance(request: true)
    end
  end

  # Raised whenever a stage instance is created.
  class StageInstanceCreateEvent < StageInstanceEvent; end

  # Raised whenever a stage instance is updated.
  class StageInstanceUpdateEvent < StageInstanceEvent; end

  # Raised whenever a stage instance is deleted.
  class StageInstanceDeleteEvent < StageInstanceEvent
    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @channel = bot.channel(data['channel_id'].to_i)
      @stage_instance = Discordrb::StageInstance.new(data, channel, @bot)
    end
  end

  # Generic event handler class for stage instance events.
  class StageInstanceEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      return false unless event.is_a?(StageInstanceEvent)

      [
        matches_all(@attributes[:topic], event.stage_instance.topic) do |a, e|
          case a
          when Regexp
            a.match?(e)
          else
            a == e
          end
        end,

        matches_all(@attributes[:channel], event.stage_instance.channel) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:server], event.stage_instance.channel.server) do |a, e|
          a&.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:scheduled_event], event.stage_instance.scheduled_event_id) do |a, e|
          a&.resolve_id == e&.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Event handler for :STAGE_INSTANCE_CREATE events.
  class StageInstanceCreateEventHandler < StageInstanceEventHandler; end

  # Event handler for :STAGE_INSTANCE_UPDATE events.
  class StageInstanceUpdateEventHandler < StageInstanceEventHandler; end

  # Event handler for :STAGE_INSTANCE_DELETE events.
  class StageInstanceDeleteEventHandler < StageInstanceEventHandler; end
end
