# frozen_string_literal: true

module Discordrb
  # A Discord Sticker
  class Sticker
    include IDObject

    # Map of sticker format types
    # https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-format-types
    FORMAT_TYPES = {
      png: 1,
      apng: 2,
      lottie: 3
    }.freeze

    # Map of sticker types
    # https://discord.com/developers/docs/resources/sticker#sticker-object-sticker-types
    TYPES = {
      standard: 1,
      guild: 2
    }.freeze


    # @return [Integer, nil] id of the pack the sticker is from. only for standard sticker type
    attr_reader :pack_id

    # @return [String] the name of the sticker
    attr_reader :name

    # @return [String, nil] the description of the sticker
    attr_reader :description

    # @return [String] the suggestion tags for the sticker
    attr_reader :tags

    # @return [Integer] the type of the sticker
    attr_reader :type

    # @return [Integer] the format type of the sticker
    attr_reader :format_type

    # @return [true, false, nil] whether this guild sticker can be used, may be false due to loss of Server Boosts.
    attr_reader :available
    alias_method :available?, :available

    # @return [Integer, nil] id of the guild that owns this sticker
    attr_reader :guild_id

    # @return [User, nil] the user that uploaded the guild sticker
    attr_reader :user
    alias_method :author, :user

    # @return [Integer, nil] the standard sticker's sort order within its pack
    attr_reader :sort_value

    def initialize(data, bot)
      @id = data['id'].to_i
      @pack_id = data['pack_id']&.to_i
      @name = data['name']
      @description = data['description'] || false
      @tags = data['tags']
      @type = data['type'].to_i
      @format_type = data['format_type'].to_i
      @available = data['available']
      @guild_id = data['guild_id']

      @user = bot.ensure_user(data['user']) if data.key?('user')
      @sort_value = data['sort_value']&.to_i
    end

    def update(**attributes)
      data = attributes.slice(:name, :description, :tags, :reason)
      Discordrb::API::Sticker.modify(@bot.token, guild_id, id, data)
    end

    def delete(reason)
      Discordrb::API::Sticker.delete(@bot.token, @guild_id, id, reason)
    end

    # The inspect method is overwritten to give more useful output
    def inspect
      "<Sticker name=\"#{name}\" id=#{id} format_type=#{format_type} user=#{@user}>"
    end
  end
end
