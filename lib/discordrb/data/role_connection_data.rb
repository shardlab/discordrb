# frozen_string_literal: true

module Discordrb
  # Metadata about a role's linked connection.
  class RoleConnectionMetadata
    # Map of connection types.
    TYPES = {
      integer_less_than_or_equal: 1,
      integer_greater_than_or_equal: 2,
      integer_equal: 3,
      integer_not_equal: 4,
      datetime_less_than_or_equal: 5,
      datetime_greater_than_or_equal: 6,
      boolean_equal: 7,
      boolean_not_equal: 8
    }.freeze

    # @return [String] the key of the metadata field.
    attr_reader :key

    # @return [String] the name of the metadata field.
    attr_reader :name

    # @return [Integer] the value of the metadata field.
    attr_reader :type

    # @return [String] the description of the metadata field.
    attr_reader :description

    # @return [Hash<String => String>] the name localizations of the metadata field.
    attr_reader :name_localizations

    # @return [Hash<String => String>] the description localizations of the metadata field.
    attr_reader :description_localizations

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @key = data['key']
      @name = data['name']
      @type = data['type']
      @description = data['description']
      @name_localizations = data['name_localizations'] || {}
      @description_localizations = data['description_localizations'] || {}
    end

    # @!method integer_less_than_or_equal?
    #   @return [true, false] whether the numeric metadata value is less than or equivalent to the server's configured numeric value.
    # @!method integer_greater_than_or_equal?
    #   @return [true, false] whether the numeric metadata value is greater than or equivalent to the server's configured numeric value.
    # @!method integer_equal?
    #   @return [true, false] whether the numeric metadata value is equivalent to the server's configured numeric value.
    # @!method integer_not_equal?
    #   @return [true, false] whether the numeric metadata value is not equivalent to the server's configured numeric value.
    # @!method datetime_less_than_or_equal?
    #   @return [true, false] whether the ISO8601 date is less than or equivalent to the server's configured number of days before a date.
    # @!method datetime_greater_than_or_equal?
    #   @return [true, false] whether the ISO8601 date is greater than or equivalent to the server's configured number of days before a date.
    # @!method boolean_equal?
    #   @return [true, false] whether the boolean metadata value is equivalent to the server's configured boolean value.
    # @!method boolean_not_equal?
    #   @return [true, false] whether the boolean metadata value is not equivalent to the server's configured boolean value.
    TYPES.each do |name, value|
      define_method("#{name}?") do
        @type == value
      end
    end
  end
end
