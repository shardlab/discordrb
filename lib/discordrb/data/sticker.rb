# frozen_string_literal: true

module Discordrb
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

    attr_reader :pack_id
    attr_reader :name
    attr_reader :description
    attr_reader :tags
    attr_reader :type
    attr_reader :format_type
    attr_reader :available
    attr_reader :guild_id

    attr_reader :user
    alias user author

    attr_reader :sort_value

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

    # The inspect method is overwritten to give more useful output
    def inspect
      "<Sticker name=\"#{name}\" id=#{id} format_type=#{format_type} user=#{@user}>"
    end

    private

    def parse_format_type(type)
      raise ArgumentError, 'Invalid sticker format type specified' unless FORMAT_TYPE.keys.include?(type)

      FORMAT_TYPE[type]
    end
  end
end
