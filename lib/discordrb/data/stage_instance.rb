# frozen_string_literal: true

module Discordrb
  # Metadata about a live stage.
  class StageInstance
    include IDObject

    # @return [String] the topic of the stage instance.
    attr_reader :topic

    # @return [Channel] the stage channel of the stage instance.
    attr_reader :channel

    # @return [Integer, nil] the ID of the scheduled event associated
    #   with the stage instance.
    attr_reader :scheduled_event_id

    # @!visibility private
    def initialize(data, channel, bot)
      @bot = bot
      @id = data['id'].to_i
      @channel = channel
      update_data(data)
    end

    # Get the stage instance's server.
    # @return [Server] The server of the stage instance.
    def server
      @channel.server
    end

    # Modify the properties of the stage instance.
    # @param topic [String] The new 1-120 character topic of the stage instance.
    # @param reason [String, nil] The reason to show in the audit log for updating the stage instance.
    # @return [nil]
    def modify(topic: :undef, reason: nil)
      update_data(JSON.parse(API::Channel.update_stage_instance(@bot.token, @channel.id, topic:, reason:)))
      nil
    end

    # Get the scheduled event associated with the stage instance.
    # @return [ScheduledEvent, nil] The scheduled event associated with the stage instance, or `nil`.
    def scheduled_event
      server.scheduled_event(@scheduled_event_id) if @scheduled_event_id
    end

    # Permanenty delete the stage instance; this cannot be undone.
    # @param reason [String, nil] The reason to show in the audit log for deleting the stage instance.
    # @return [nil]
    def delete(reason: nil)
      API::Channel.delete_stage_instance(@bot.token, @channel.id, reason: reason)
      server.delete_stage_instance(@id)
      nil
    end

    # @!visibility private
    def update_data(new_data)
      @topic = new_data['topic']
      @scheduled_event_id = new_data['guild_scheduled_event_id']&.to_i
    end

    # @!visibility private
    def inspect
      "<StageInstance id=#{@id} topic=\"#{@topic}\" scheduled_event_id=#{@scheduled_event_id}>"
    end
  end
end
