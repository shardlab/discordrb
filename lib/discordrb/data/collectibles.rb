# frozen_string_literal: true

module Discordrb
  # Collectibles are resources such as nameplates that can be collected by users.
  class Collectibles
    # @return [Nameplate, nil] the nameplate the user has collected or nil.
    attr_reader :nameplate

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @nameplate = Nameplate.new(data['nameplate'], bot) if data['nameplate']
    end

    # Collectable background images shown on a user's name in the member's tab.
    class Nameplate
      # @return [Integer] ID of the nameplate's SKU.
      attr_reader :sku_id

      # @return [String] the path to the nameplate asset.
      attr_reader :asset

      # @return [String] the label of the nameplate.
      attr_reader :label

      # @return [Symbol] the background color of the nameplate.
      attr_reader :palette

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @sku_id = data['sku_id']&.to_i
        @asset = data['asset']
        @label = data['label']
        @palette = data['palette'].to_sym
      end

      # Utility method to get the URL of this nameplate.
      # @param static [true, false] Whether to return the static URL of this
      #   nameplate instead of the animated URL.
      # @return [String] The CDN url of this nameplate.
      def url(static: false)
        static ? API.static_nameplate_url(@asset) : API.nameplate_url(@asset)
      end
    end
  end
end
