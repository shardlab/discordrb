# frozen_string_literal: true

module Discordrb
  # Server Scheduled Event
  # 
  # Note that this should not be confused with Discordrb::Events, which
  # represent events sent whenever something occurs in a guild or on a user
  # (e.g. Guild creation, message sending, etc).
  #
  # These are for Scheduled Events, which are guild activities like "World of
  # Warcraft Raid" or a groupwatch of a movie.
  class ScheduledEvent
    include IDObject

    STATUSES = {
      1 => :scheduled,
      2 => :active,
      3 => :completed,
      4 => :canceled
    }.freeze

    PRIVACY_LEVELS = {
      2 => :guild_only
    }.freeze

    ENTITY_TYPES = {
      1 => :stage,
      2 => :voice,
      3 => :external
    }.freeze

    # @return [String] the name of the scheduled event.
    attr_reader :name

    # @return [String, nil] the description of the scheduled event.
    attr_reader :description

    # @return [String, nil] The URL for the scheduled event's cover image, if any.
    attr_reader :image

    # @return [Server, nil] the server of this scheduled event.
    attr_reader :server

    # @return [Time] the timestamp at which this event is scheduled to begin.
    attr_reader :scheduled_start_time

    # @return [Time, nil] the timestamp at which this event is scheduled to end, or nil if it has no defined end.
    attr_reader :scheduled_end_time

    # @return [Integer, nil] the number of users subscribed to a given event.
    attr_reader :user_count

    # @return [User, nil] the user that sent this message (will usually be a User, can be `nil` for very old scheduled events)
    attr_reader :creator
    alias_method :user, :creator

    # @return [Channel, nil] the channel that this event will be hosted in, or nil if there's no associated channel.
    attr_reader :channel

    # @return [Symbol] The status of the scheduled event. One of `:scheduled`, `:active`, `:completed`, or `:canceled`.
    attr_reader :status

    # @return [Symbol] The privacy level of the scheduled event. Currently always `:guild_only`.
    attr_reader :privacy_level

    # @return [Symbol] The entity type of the scheduled event. One of `:stage`, `:voice`, or `:external`.
    attr_reader :entity_type

    # @return [String, nil] The ID of an entity associated with the scheduled event, if any.
    attr_reader :entity_id

    # @return [Hash, nil] Additional metadata for the scheduled event, if any. Can include the location information for the event.
    attr_reader :entity_metadata

    # @!visibility private
    def initialize(data, bot, server = nil)
      @bot = bot

      @server = server
      @id = data['id'].nil? ? nil : data['id'].to_i

      @name = data['name']
      @description = data['description']

      @scheduled_start_time = Time.parse(data['scheduled_start_time'])
      @scheduled_end_time = Time.parse(data['scheduled_end_time']) if data['scheduled_end_time']

      @user_count = data['user_count']

      @creator = data['creator'] ? (@bot.user(data['creator']['id'].to_i) || User.new(data['creator'], bot)) : nil
      @channel = data['channel_id'] ? @bot.channel(data['channel_id'].to_i) : nil

      @status = STATUSES[data['status']]
      @privacy_level = PRIVACY_LEVELS[data['privacy_level']]

      @entity_type = ENTITY_TYPES[data['entity_type']]
      @entity_id = data['entity_id']
      @entity_metadata = data['entity_metadata']

      @image = data['image']
    end

    # @return [Boolean] Whether the event is scheduled.
    def scheduled?
      @status == :scheduled
    end

    # @return [Boolean] Whether the event is currently active.
    def active?
      @status == :active
    end

    # @return [Boolean] Whether the event was canceled.
    def canceled?
      @status == :canceled
    end

    alias_method :cancelled?, :canceled?
    
    # @return [Boolean] Whether the event has completed.
    def completed?
      @status == :completed
    end

    # @return [Boolean] Whether the event is an external event.
    def external?
      @entity_type == :external
    end

    # The inspect method is overwritten to give more useful output
    def inspect
      "<ScheduledEvent name=\"#{@name}\" id=#{@id} description=\"#{@description}\" scheduled_start_time=#{@scheduled_start_time} scheduled_end_time=#{@scheduled_end_time} status=#{@status}>"
    end

  end
end
