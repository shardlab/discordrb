# frozen_string_literal: true

module Discordrb
  # A reaction to a message.
  class Reaction
    # Map of reaction types
    TYPES = {
      normal: 0,
      burst: 1
    }.freeze

    # @return [Integer] the total amount of users who have reacted with this reaction (including burst reactions)
    attr_reader :count

    # @return [true, false] whether the current bot or user used this reaction
    attr_reader :me
    alias_method :me?, :me

    # @return [Integer] the ID of the emoji, if it was custom
    attr_reader :id

    # @return [String] the name or unicode representation of the emoji
    attr_reader :name

    # @return [true, false] whether the current bot or user used this reaction as a burst reaction
    attr_reader :me_burst
    alias_method :me_burst?, :me_burst

    # @return [Array<ColourRGB>] an array of colors used for animations in burst reactions
    attr_reader :burst_colours
    alias_method :burst_colors, :burst_colours

    # @return [Integer] the total amount of users who have reacted with this reaction as a burst reaction
    attr_reader :burst_count

    # @return [Integer] the total amount of users who have reacted with this reaction as a normal reaction
    attr_reader :normal_count

    # @!visibility private
    def initialize(data)
      @count = data['count']
      @me = data['me']
      @id = data['emoji']['id']&.to_i
      @name = data['emoji']['name']
      @me_burst = data['me_burst']
      @burst_colours = data['burst_colors'].map { |b| ColourRGB.new(b.delete('#')) }
      @burst_count = data['count_details']['burst']
      @normal_count = data['count_details']['normal']
    end

    # Converts this Reaction into a string that can be sent back to Discord in other reaction endpoints.
    # If ID is present, it will be rendered into the form of `name:id`.
    # @return [String] the name of this reaction, including the ID if it is a custom emoji
    def to_s
      id.nil? ? name : "#{name}:#{id}"
    end
  end
end
