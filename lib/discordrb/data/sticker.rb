# frozen_string_literal: true

module Discordrb
  # A Discord Sticker
  class Sticker
    include IDObject

    FORMAT_TYPE = {
      png: 1,
      apng: 2,
      lottie: 3
    }.freeze

    TYPES = {
      standard: 1,
      guild: 2
    }.freeze

    attr_reader :pack_id, :name, :description, :tags, :type, :format_type, :available, :guild_id, :user, :sort_value
    alias author user

    def initialize(data, bot)
      data.symbolize_keys!
      @id = data[:id].to_i
      @pack_id = data[:pack_id].to_i
      @name = data[:name]
      @description = data[:description]
      @tags = data[:tags].split(',')
      @type = TYPES.index(data[:type].to_i)
      @format_type = FORMAT_TYPE.index(data[:format_type].to_i)
      @available = data[:available]
      @guild_id = data[:guild_id]
      @user = bot.users.find { |user| user.id == data[:user]['id'].to_i }
      @sort_value = data[:sort_value]
    end

    def update(**attributes)
      data = attributes.slice(:name, :description, :tags, :reason)
      Discordrb::API::Sticker.modify(@bot.token, guild_id, id, data)
    end

    def destroy(reason)
      Discordrb::API::Sticker.destroy(@bot.token, @guild_id, id, reason)
    end

    # The inspect method is overwritten to give more useful output
    def inspect
      "<Sticker name=\"#{name}\" id=#{id} format_type=#{format_type} user=#{@user}>"
    end
  end
end
