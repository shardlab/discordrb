# frozen_string_literal: true

module Discordrb
  module Components
    class RowBuilder
      # @!visibility private
      def initialize
        @components = []
      end

      def button(style:, label: nil, emoji: nil, custom_id: nil, disabled: nil, url: nil)
        @components << { type: 2, label: label, emoji: emoji, style: style, custom_id: custom_id, disabled: disabled, url: url }
      end

      def to_h
        { type: 1, components: @components }
      end
    end

    class View
      def initialize
        @rows = []

        yield self if block_given?
      end

      def row
        new_row = RowBuilder.new

        yield new_row

        @rows << new_row.to_h
      end

      def to_a
        @rows
      end
    end

    # @!visibility private
    def self.from_data(data, bot)
      case data['type']
      when ActionRow::TYPE
        ActionRow.new(data, bot)
      when Button::TYPE
        Button.new(data, bot)
      end
    end

    # Represents a row of components
    class ActionRow
      include Enumerable
      
      # Component type
      TYPE = 1

      # @return [Array<Button>]
      attr_reader :componenets

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @componenets = data['components'].map { |component_data| Components.from_data(component_data, @bot) }
      end

      # Iterate over each component in the row.
      def each(&block)
        @componenets.each(&block)
      end

      # Get all buttons in this row
      # @return [Array<Button>]
      def buttons
        select {|component| component.is_a? Button }
      end
    end

    class Button
      # Component type
      TYPE = 2

      # @return [String]
      attr_reader :label

      # @return [Integer]
      attr_reader :style

      # @return [String]
      attr_reader :custom_id

      # @return [true, false]
      attr_reader :disabled

      # @return [String, nil]
      attr_reader :url

      # @return [Emoji, nil]
      attr_reader :emoji

      # @!visibility private
      def initialize(data, bot)
        @bot = bot

        @label = data['label']
        @style = data['style']
        @custom_id = data['custom_id']
        @disabled = data['disabled']
        @url = data['url']
        @emoji = Emoji.new(data['emoji'], @bot) if data['emoji']
      end

      # Possible button style names and values.
      STYLES = {
        primary: 1,
        secondary: 2,
        success: 3,
        danger: 4,
        link: 5
      }

      # @method primary?
      #   @return [true, false]
      # @method secondary?
      #   @return [true, false]
      # @method success?
      #   @return [true, false]
      # @method danger?
      #   @return [true, false]
      # @method link?
      #   @return [true, false]
      STYLES.each do |name, value|
        define_method("#{name}?") do
          @style == value
        end
      end

      def await_click(key, **attributes, &block)
        @bot.add_await(key, Discordrb::Events::ButtonEvent, { custom_id: @custom_id }.merge(attributes), &block)
      end

      def await_click!(**attributes, &block)
        @bot.add_await!(Discordrb::Events::ButtonEvent, { custom_id: @custom_id }.merge(attributes), &block)
      end
    end
  end
end
