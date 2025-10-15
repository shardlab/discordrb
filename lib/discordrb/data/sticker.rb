# frozen_string_literal: true

module Discordrb
  # Server sticker
  class Sticker
    FORMATS = {
      png: 1,
      apng: 2,
      lottie: 3,
      gif: 4
    }.freeze

    class Item
      include IDObject

      FORMATS.each do |name, value|
        define_method("#{name}?") do
          @format_type == value
        end
      end

      # @return [Message] the message this sticker belongs to.
      attr_reader :message

      # @return [String] the sticker name
      attr_reader :name

      # @return [String] the sticker description
      attr_reader :description

      # @return [Integer] the sticker type
      attr_reader :format_type

      # @return [String] the sticker extension
      attr_reader :extension

      # @!visibility private
      def initialize(data, message, bot)
        @bot = bot
        @message = message

        @name = data['name']
        @description = data['description']
        @id = data['id']&.to_i
        @format_type = data['format_type']

        case @format_type
        when 1, 2
          @extension = 'png'
        when 3
          @extension = 'json'
        when 4
          @extension = 'gif'
        end
      end
    end
  end
end
