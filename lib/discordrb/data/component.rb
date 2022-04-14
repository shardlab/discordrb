# frozen_string_literal: true

module Discordrb
  # Components are interactable interfaces that can be attached to messages.
  module Components
    # @deprecated This alias will be removed in future releases.
    class View < Webhooks::View
    end

    # @!visibility private
    def self.from_data(data, bot)
      case data['type']
      when Webhooks::View::COMPONENT_TYPES[:action_row]
        ActionRow.new(data, bot)
      when Webhooks::View::COMPONENT_TYPES[:button]
        Button.new(data, bot)
      when Webhooks::View::COMPONENT_TYPES[:select_menu]
        SelectMenu.new(data, bot)
      end
    end

    # Represents a row of components
    class ActionRow
      include Enumerable

      # @return [Array<Button>]
      attr_reader :components

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @components = data['components'].map { |component_data| Components.from_data(component_data, @bot) }
      end

      # Iterate over each component in the row.
      def each(&block)
        @components.each(&block)
      end

      # Get all buttons in this row
      # @return [Array<Button>]
      def buttons
        select { |component| component.is_a? Button }
      end

      # @!visibility private
      def to_a
        @components
      end
    end

    # An interactable button component.
    class Button
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
      Webhooks::View::BUTTON_STYLES.each do |name, value|
        define_method("#{name}?") do
          @style == value
        end
      end

      # Await a button click
      def await_click(key, **attributes, &block)
        @bot.add_await(key, Discordrb::Events::ButtonEvent, { custom_id: @custom_id }.merge(attributes), &block)
      end

      # Await a button click, blocking.
      def await_click!(**attributes, &block)
        @bot.add_await!(Discordrb::Events::ButtonEvent, { custom_id: @custom_id }.merge(attributes), &block)
      end
    end

    # An interactable select menu component.
    class SelectMenu
      # A select menu option.
      class Option
        # @return [String]
        attr_reader :label

        # @return [String]
        attr_reader :value

        # @return [String, nil]
        attr_reader :description

        # @return [Emoji, nil]
        attr_reader :emoji

        # @!visibility hidden
        def initialize(data)
          @label = data['label']
          @value = data['value']
          @description = data['description']
          @emoji = Emoji.new(data['emoji'], @bot) if data['emoji']
        end
      end

      # @return [String]
      attr_reader :custom_id

      # @return [Integer, nil]
      attr_reader :max_values

      # @return [Integer, nil]
      attr_reader :min_values

      # @return [String, nil]
      attr_reader :placeholder

      # @return [Array<Option>]
      attr_reader :options

      # @!visibility private
      def initialize(data, bot)
        @bot = bot

        @max_values = data['max_values']
        @min_values = data['min_values']
        @placeholder = data['placeholder']
        @custom_id = data['custom_id']
        @emoji = Emoji.new(data['emoji'], @bot) if data['emoji']
        @options = data['options'].map { |opt| Option.new(opt) }
      end
    end
  end
end
