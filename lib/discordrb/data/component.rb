# frozen_string_literal: true

module Discordrb
  # Components are interactable interfaces that can be attached to messages.
  module Components
    # Component types.
    # @see https://discord.com/developers/docs/interactions/message-components#component-types
    TYPES = {
      action_row: 1,
      button: 2,
      select_menu: 3
    }.freeze

    # This builder is used when constructing an ActionRow. All current components must be within an action row, but this can
    # change in the future. A message can have 5 action rows, each action row can hold a weight of 5. Buttons have a weight of 1,
    # and dropdowns have a weight of 5.
    class RowBuilder
      # @!visibility private
      def initialize
        @components = []
      end

      # Add a button to this action row.
      # @param style [Symbol, Integer] The button's style type. See {Button::STYLES}
      # @param label [String, nil] The text label for the button. Either a label or emoji must be provided.
      # @param emoji [Emoji, String, Integer] An Emoji, emoji ID, or unicode emoji to attach to the button.
      # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
      #   There is a limit of 100 characters to each custom_id.
      # @param disabled [true, false] Whether this button is disabled and shown as greyed out.
      # @param url [String, nil] The URL, when using a link style button.
      def button(style:, label: nil, emoji: nil, custom_id: nil, disabled: nil, url: nil)
        style = Button::STYLES[style] || style

        emoji = case emoji
                when Integer, String
                  emoji.to_i.positive? ? { id: emoji } : { name: emoji }
                when Emoji
                  emoji.to_h
                end

        @components << { type: Components::TYPES[:button], label: label, emoji: emoji, style: style, custom_id: custom_id, disabled: disabled, url: url }
      end

      # Add a select menu to this action row.
      # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
      #   There is a limit of 100 characters to each custom_id.
      # @param options [Array<Hash>] Options that can be selected in this menu. Can also be provided via the yielded builder.
      # @param placeholder [String, nil] Default text to show when no entries are selected.
      # @param min_values [Integer, nil] The minimum amount of values a user must select.
      # @param max_values [Integer, nil] The maximum amount of values a user can select.
      # @yieldparam builder [SelectMenuBuilder]
      def select_menu(custom_id:, options: [], placeholder: nil, min_values: nil, max_values: nil)
        builder = SelectMenuBuilder.new(custom_id, options, placeholder, min_values, max_values)

        yield builder if block_given?

        @components << builder.to_h
      end

      # @!visibility private
      def to_json(_)
        { type: Components::TYPES[:action_row], components: @components }.to_json
      end
    end

    # A builder to assist in adding options to select menus.
    class SelectMenuBuilder
      # @!visibility hidden
      def initialize(custom_id, options = [], placeholder = nil, min_values = nil, max_values = nil)
        @custom_id = custom_id
        @options = options
        @placeholder = placeholder
        @min_values = min_values
        @max_values = max_values
      end

      # Add an option to this select menu.
      # @param label [String] The title of this option.
      # @param value [String] The value that this option represents.
      # @param description [String, nil] An optional description of the option.
      # @param emoji [Emoji, String, Integer, nil] An optional emoji to display on the left of the option title.
      # @param default [true, false, nil] Whether this is the default selected option.
      def option(label:, value:, description: nil, emoji: nil, default: nil)
        emoji = case emoji
                when Integer, String
                  emoji.to_i.positive? ? { id: emoji } : { name: emoji }
                when Emoji
                  emoji.to_h
                end

        @options << { label: label, value: value, description: description, emoji: emoji, default: default }
      end

      # @!visibility private
      def to_h
        {
          type: Components::TYPES[:select_menu],
          options: @options,
          placeholder: @placeholder,
          min_values: @min_values,
          max_values: @max_values,
          custom_id: @custom_id
        }
      end
    end

    # A reusable view representing a component collection, with builder methods.
    class View
      attr_reader :rows

      def initialize
        @rows = []

        yield self if block_given?
      end

      # Add a new ActionRow to the view
      # @yieldparam [RowBuilder]
      def row
        new_row = RowBuilder.new

        yield new_row

        @rows << new_row
      end

      # @!visibility private
      def to_a
        @rows.to_a
      end
    end

    # @!visibility private
    def self.from_data(data, bot)
      case data['type']
      when TYPES[:action_row]
        ActionRow.new(data, bot)
      when TYPES[:button]
        Button.new(data, bot)
      when TYPES[:select_menu]
        SelectMenu.new(data, bot)
      end
    end

    # Represents a row of components
    class ActionRow
      include Enumerable

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

      # Possible button style names and values.
      STYLES = {
        primary: 1,
        secondary: 2,
        success: 3,
        danger: 4,
        link: 5
      }.freeze

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
