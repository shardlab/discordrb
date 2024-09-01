# frozen_string_literal: true

module Discordrb
  # A Sticker Pack
  class Pack
    include IDObject

    # @return [String] The sticker pack name.
    attr_reader :name

    # @return [String] The sticker pack description.
    attr_reader :description

    # @return [StickerPackObject] The sticker's in this pack.
    attr_reader :stickers

    # @return [Integer] Only for sticker packs. ID of the pack's SKU.
    attr_reader :sku_id

    # @return [Integer] Only for sticker packs. ID of a sticker in the pack which is shown as the pack's icon.
    attr_reader :cover_sticker_id

    # @return [Integer] Only for sticker packs. ID of the sticker pack's banner image.
    attr_reader :banner_asset_id

    # @!visibility private
    def initialize(data, bot, _server = nil)
      @bot = bot
      @name = data['name']
      @id = data['id']&.to_i
      @description = data['description']
      @sku_id = data['sku_id']&.to_i
      @cover_sticker_id = data['cover_sticker_id']&.to_i
      @banner_asset_id = data['banner_asset_id']&.to_i
      @stickers = data['stickers']
    end
  end
end
