# frozen_string_literal: true

module Discordrb
  # A premium offering that can be made available to an entity.
  class SKU
    include IDObject

    # Map of SKU flags.
    FLAGS = {
      available: 1 << 2,
      server_subscription: 1 << 7,
      user_subscription: 1 << 8
    }.freeze

    # Map of SKU types.
    TYPES = {
      durable: 2,
      consumable: 3,
      subscription: 5,
      subscription_group: 6
    }.freeze

    # @return [String] the name of the SKU.
    attr_reader :name

    # @return [String] the slug of the SKU.
    attr_reader :slug

    # @return [Integer] the type of the SKU.
    attr_reader :type

    # @return [Integer] the flags of the SKU.
    attr_reader :flags

    # @return [Integer] the ID of the parent application for the SKU.
    attr_reader :application_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      @name = data['name']
      @slug = data['slug']
      @type = data['type']
      @flags = data['flags']
      @application_id = data['application_id']&.to_i
    end

    # @!method available?
    #   @return [true, false] whether or not the SKU is available for purchase.
    # @!method server_subscription?
    #   @return [true, false] whether or not the SKU can be purchased by a user and applied to a server.
    # @!method user_subscription?
    #   @return [true, false] whether or not the SKU can be purchased by a user for themselves.
    FLAGS.each do |name, value|
      define_method("#{name}?") do
        @flags.anybits?(value)
      end
    end

    # @!method durable?
    #   @return [true, false] whether or not the SKU is a durable one-time purchase.
    # @!method consumable?
    #   @return [true, false] whether or not the SKU is a consumable one-time purchase.
    # @!method subscription?
    #   @return [true, false] whether or not the SKU is for a recurring subscription.
    # @!method subscription_group?
    #   @return [true, false] whether or not the SKU is part of a system-generated group.
    TYPES.each do |name, value|
      define_method("#{name}?") do
        @type == value
      end
    end
  end
end
