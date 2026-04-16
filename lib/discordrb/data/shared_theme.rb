# frozen_string_literal: true

module Discordrb
  # A theme for the official Discord client.
  class SharedTheme
    # Mapping of names to base theme values.
    BASES = {
      unset: 0,
      dark: 1,
      light: 2,
      darker: 3,
      midnight: 4
    }.freeze

    # @return [Integer] the background tone of the theme.
    attr_reader :base

    # @return [Integer] the angle of the theme's colours.
    attr_reader :angle

    # @return [Array<ColourRGB>] the colours of the theme.
    attr_reader :colours
    alias colors colours

    # @return [Integer] the intensity of the theme's colours.
    attr_reader :intensity

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @base = data['base_theme']
      @intensity = data['base_mix']
      @angle = data['gradient_angle']
      @colours = data['colors']&.map { |value| ColourRGB.new(value) }
    end

    # Check if two shared theme objects are equivalent.
    # @param other [Object] The object to compare against for equality.
    # @return [true, false] Whether or not the two objects are equivalent.
    def ==(other)
      return false unless other.is_a?(SharedTheme)

      @angle == other.angle && @base == other.base &&
        @intensity == other.intensity && @colours == other.colours
    end

    alias_method :eql?, :==

    # @!method unset_base?
    #   @return [true, false] whether or not the background tone of the theme is not defined.
    # @!method dark_base?
    #   @return [true, false] whether or not the background tone of the theme is a dark color.
    # @!method light_base?
    #   @return [true, false] whether or not the background tone of the theme is a light color.
    # @!method darker_base?
    #   @return [true, false] whether or not the background tone of the theme is a darker color.
    # @!method midnight_base?
    #   @return [true, false] whether or not the background tone of the theme is a midnight color.
    BASES.each do |name, value|
      define_method("#{name}_base?") { @base == value }
    end

    # @!visibility private
    def to_h
      {
        base_theme: @base,
        base_mix: @intensity,
        gradient_angle: @angle,
        colors: @colours.map { |value| format('%06x', value.to_i) }
      }
    end

    # @!visibility private
    def inspect
      "<SharedTheme base=#{@base} angle=#{@angle} intensity=#{@intensity}>"
    end

    # Builder for shared themes.
    class Builder
      # Create a shared theme object.
      # @param angle [Integer] The angle of the theme's colours; between 0-360.
      # @param intensity [Integer] The intensity of the theme's colours; between 0-100.
      # @param base [Integer, Symbol, nil] The background tone of the theme; see {BASES}.
      def initialize(angle:, intensity:, base: :unset)
        @base = base
        @colours = []
        @angle = angle
        @intensity = intensity
      end

      # Add a colour to the shared theme.
      # @param value [Integer, String, ColourRGB] The colour to add to the theme's colours.
      # @return [void]
      def colour(value)
        raise 'Maximum number of shared theme colours reached (5)' if @colours.length == 5

        @colours << format('%06x', value.is_a?(String) ? value&.delete('#')&.to_i(16) : value&.to_i)
      end

      alias_method :color, :colour
      alias_method :add_color, :colour
      alias_method :add_colour, :colour

      # @!visibility private
      def to_h
        {
          colors: @colours,
          base_mix: @intensity.to_i,
          gradient_angle: @angle.to_i,
          base_theme: BASES[@base] || @base
        }
      end
    end
  end
end
