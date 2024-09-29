# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/guild-scheduled-event
    module GuildScheduledEventEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/guild-scheduled-event#list-scheduled-events-for-guild
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @return [Hash<Symbol, Object>]
      def list_scheduled_events_for_guild(guild_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/scheduled-events", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/auto-moderation#get-guild-scheduled-event
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param guild_scheduled_event_id [Integer, String] An ID that uniquely identifies a scheduled event.
      # @return [Hash<Symbol, Object>]
      def get_guild_scheduled_event(guild_id, guild_scheduled_event_id, **params)
        request Route[:GET, "/guilds/#{guild_id}/scheduled-events/#{guild_scheduled_event_id}", guild_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild-scheduled-event#create-guild-scheduled-event
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param channel_id [Integer, String] The channel ID for this scheduled event.
      # @param entity_metadata [String] Location of the event. Required for external event types.
      # @param name [String] Name of the event.
      # @param privacy_level [Integer] Who the scheduled event can be accessed by.
      # @param scheduled_start_time [Time] A time object that indicates when to start the event.
      # @param scheduled_end_time [Time] A time object that indicates when to end the event.
      # @param description [String] Description of the scheduled event.
      # @param entity_type [Integer] The location of the event; E.g. voice, stage-instance, etc.
      # @param image [String, #read] A base64 encoded string with the image data.
      # @param recurrence_rule [Hash<Symbol, Object>] A recurrence rule object. See the offical API docs for more info.
      # @param reason [String] The reason for creating this scheduled event.
      # @return [Hash<Symbol, Object>]
      def create_guild_scheduled_event(guild_id, channel_id: :undef, entity_metadata: :undef, name:, privacy_level: :undef,
                                       scheduled_start_time: :undef, scheduled_end_time: :undef, description: :undef,
                                       entity_type: :undef, image: :undef, recurrence_rule: :undef, reason: :undef, **rest)
        data = {
          channel_id: channel_id,
          entity_metadata: entity_metadata,
          name: name,
          privacy_level: privacy_level,
          scheduled_start_time: scheduled_start_time,
          scheduled_end_time: scheduled_end_time,
          description: description,
          entity_type: entity_type,
          image: image,
          recurrence_rule: recurrence_rule,
          **rest
        }

        request Route[:POST, "/guilds/#{guild_id}/scheduled-events"],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild-scheduled-event#modify-guild-scheduled-event
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param guild_scheduled_event_id [Integer, String] An ID that uniquely identifies a scheduled event.
      # @param channel_id [Integer, String] The channel ID for this scheduled event.
      # @param entity_metadata [String] Location of the event. Required for external event types.
      # @param name [String] New name of the event.
      # @param privacy_level [Integer] Who the scheduled event can be accessed by.
      # @param scheduled_start_time [Time] A time object that indicates when to start the event.
      # @param scheduled_end_time [Time] A time object that indicates when to end the event.
      # @param description [String] Description of the scheduled event.
      # @param entity_type [Integer] The location of the event; E.g. voice, stage-instance, etc.
      # @param image [String, #read] A base64 encoded string with the image data.
      # @param recurrence_rule [Hash<Symbol, Object>] A recurrence rule object. See the offical API docs for more info.
      # @param reason [String] The reason for updating this scheduled event.
      # @return [Hash<Symbol, Object>]
      def modify_guild_scheduled_event(guild_id, guild_scheduled_event_id:, channel_id: :undef, entity_metadata: :undef,
                                       name: :undef, privacy_level: :undef, scheduled_start_time: :undef, scheduled_end_time: :undef,
                                       description: :undef, entity_type: :undef, status: :undef, image: :undef, recurrence_rule: :undef,
                                       reason: :undef, **rest)
        data = {
          channel_id: channel_id,
          entity_metadata: entity_metadata,
          name: name,
          privacy_level: privacy_level,
          scheduled_start_time: scheduled_start_time,
          scheduled_end_time: scheduled_end_time,
          description: description,
          entity_type: entity_type,
          status: status,
          image: image,
          recurrence_rule: recurrence_rule,
          **rest
        }

        request Route[:PATCH, "/guilds/#{guild_id}/scheduled-events/#{guild_scheduled_event_id}"],
                body: filter_undef(data),
                reason: reason
      end

      # @!discord_api https://discord.com/developers/docs/resources/guild-scheduled-event#delete-guild-scheduled-event
      # @param guild_id [Integer, String] An ID that uniquely identifies a guild.
      # @param guild_scheduled_event_id [Integer, String] An ID that uniquely identifies a scheduled event.
      # @return [nil]
      def delete_guild_scheduled_event(guild_id, guild_scheduled_event_id)
        request Route[:DELETE, "/guilds/#{guild_id}/scheduled-events/#{guild_scheduled_event_id}"],
      end
    end
  end
end
