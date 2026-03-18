# frozen_string_literal: true

module Discordrb
  # A timestamp referenced in a message via markdown.
  class TimestampMarkdown
    # Mapping of timestamp styles.
    STYLES = {
      short_time: 't', # 16:20
      long_time: 'T', # 16:20:30
      short_date: 'd', # 20/04/2021
      long_date: 'D', # 20 April 2021
      short_datetime: 'f', # 20 April 2021 16:20
      long_datetime: 'F', # Tuesday, 20 April 2021 16:20
      relative: 'R', # 2 months ago
      simple_datetime: 's', # 20/04/2021, 16:20
      medium_datetime: 'S' # 20/04/2021, 16:20:30
    }.freeze

    # @return [Time] the time that the timestamp is referencing.
    attr_reader :time

    # @!visibility private
    def initialize(time, style)
      @time = time
      @style = style
    end

    # Get the specifier used to determine the style of the timestamp.
    # @return [String] the formatting specifier used to display the timestamp.
    def style
      @style || 'f'
    end

    # Get a string that will allow you to display the time in the Discord client.
    # @return [String] The timestamp serialized as a string for the Discord client.
    def to_s
      Discordrb.timestamp(@time, @style)
    end

    # Check if the timestamp markdown object is equivalent to another object.
    # @param other [TimestampMarkdown, Object] The object to check against for equality.
    # @return [true, false] Whether or not the two objects are equivalent to each other.
    def ==(other)
      other.is_a?(TimestampMarkdown) ? (other.style == style) && (other.time == time) : false
    end

    alias_method :eql?, :==

    # @!visibility private
    def inspect
      "<TimestampMarkdown time=#{@time.to_i} style=\"#{style}\">"
    end

    # @!method short_time?
    #   @return [true, false] whether or not the timestamp is displayed in a format such as `16:20`.
    # @!method long_time?
    #   @return [true, false] whether or not the timestamp is displayed in a format such as `16:20:30`.
    # @!method short_date?
    #   @return [true, false] whether or not the timestamp is displayed in a format such as `20/04/2021`.
    # @!method long_date?
    #   @return [true, false] whether or not the timestamp is displayed in a format such as `20 April 2021`.
    # @!method short_datetime?
    #   @return [true, false] whether or not the timestamp is displayed in a format such as `20 April 2021 16:20`.
    # @!method long_datetime?
    #   @return [true, false] whether or not the timestamp is displayed in a format such as `Tuesday, 20 April 2021 16:20`.
    # @!method relative?
    #   @return [true, false] whether or not the timestamp is displayed in a format such as `2 months ago`.
    # @!method simple_datetime?
    #   @return [true, false] whether or not the timestamp is displayed in a format such as `20/04/2021, 16:20`.
    # @!method medium_datetime?
    #   @return [true, false] whether or not the timestamp is displayed in a format such as ` 20/04/2021, 16:20:30`.
    STYLES.each do |name, value|
      define_method("#{name}?") do
        style == value
      end
    end
  end
end
