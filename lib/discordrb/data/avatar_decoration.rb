# frozen_string_literal: true

module Discordrb
  # A decoration displayed on a user's avatar.
  class AvatarDecoration
    # @return [Integer] the ID of the avatar decoration's SKU.
    attr_reader :sku_id

    # @return [String] the ID of the avatar decoration, can be used to generate an avatar decoration URL.
    # @see #url
    attr_reader :decoration_id

    # @return [Time, nil] The time at when the avatar decoration expires.
    attr_reader :expires_at

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @sku_id = data['sku_id']&.to_i
      @decoration_id = data['asset']
      @expires_at = Time.at(data['expires_at']) if data['expires_at']
    end

    # Utility method to get an avatar decoration URL.
    # @return [String] the URL to the avatar decoration.
    def url
      API.avatar_decoration_url(@decoration_id)
    end

    # @return [true, false] if this avatar decoration will only last temporarily.
    def temporary?
      !@expires_at.nil?
    end
  end
end
