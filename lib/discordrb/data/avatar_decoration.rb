# frozen_string_literal: true

module Discordrb
  # A decoration displayed on a user's avatar.
  class AvatarDecoration
    # @return [Integer] ID of the avatar decoration's SKU.
    attr_reader :sku_id

    # @return [String] ID that can be used to generate an avatar decoration URL.
    # @see #url
    attr_reader :decoration_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @sku_id = data['sku_id']&.to_i
      @decoration_id = data['asset']
    end

    # Utility method to get an avatar decoration URL.
    # @return [String] the URL to the avatar decoration.
    def url
      API.avatar_decoration_url(@decoration_id)
    end
  end
end
