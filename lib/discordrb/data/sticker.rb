# frozen_string_literal: true

module Discordrb
  # stickers
  class Sticker
    include IDObject

    FORMAT = {
      1 => :png,
      2 => :apng,
      3 => :lottie,
      4 => :gif
    }.freeze

    TYPE = {
      1 => :standard,
      2 => :server
    }.freeze

    # @return [String] The sticker's name.
    attr_reader :name

    # @return [String] The sticker's description.
    attr_reader :description

    # @return [String] The sticker's tags.
    attr_reader :tags

    # @return [String] The sticker's type: https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-types
    attr_reader :type

    # @return [String] The file type of this sticker.
    attr_reader :format

    # @return [Boolean] If this sticker can be used.
    attr_reader :usable
    alias_method :usable?, :usable

    # @return [Integer] The ID of the server this sticker originates from.
    attr_reader :server_id

    # @return [Integer] The ID of the user that uploaded this sticker.
    attr_reader :member

    # @return [Integer] The sort order of this sticker if it's part of a pack.
    attr_reader :sort_order

    # @return [Integer] The ID of the pack if this sticker belongs to one.
    attr_reader :pack_id

    # @!visibility private
    def initialize(data, bot, _server = nil)
      @bot = bot
      @name = data['name']
      @id = data['id']&.to_i
      @tags = data['tags']
      @type = TYPE[data['type']]
      @format = FORMAT[data['format_type']]
      @description = data['description']
      @pack_id = data['pack_id']&.to_i
      @sort_order = data['sort_value']&.to_i
      @usable = data['available']
      @server_id = data['guild_id']&.to_i
      @member = data['user']
    end

    # @return [String] the file URL of the sticker
    def file_url
      API.sticker_file_url(id)
    end
  end
end
