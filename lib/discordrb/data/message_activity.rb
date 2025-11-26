# frozen_string_literal: true

module Discordrb
  # A rich-presence activity attached to a message.
  class MessageActivity
    # Map of activity types.
    TYPES = {
      join: 1,
      spectate: 2,
      listen: 3,
      join_request: 5
    }.freeze

    # @return [Integer] the type of the activity.
    attr_reader :type

    # @return [String, nil] the party ID of the activity.
    attr_reader :party_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @type = data['type']
      @party_id = data['party_id']
    end

    # @!method join?
    #   @return [true, false] whether or not the activity type is join.
    # @!method spectate?
    #   @return [true, false] whether or not the activity type is spectate.
    # @!method listen?
    #   @return [true, false] whether or not the activity type is listen.
    # @!method join_request?
    #   @return [true, false] whether or not the activity type is a join request.
    TYPES.each do |name, value|
      define_method("#{name}?") do
        @type == value
      end
    end
  end
end
