# frozen_string_literal: true

# A reusable view representing a component collection, with builder methods.
class Discordrb::Webhooks::View
  # Possible button style names and values.
  BUTTON_STYLES = {
    primary: 1,
    secondary: 2,
    success: 3,
    danger: 4,
    link: 5
  }.freeze

  # Component types.
  # @see https://discord.com/developers/docs/interactions/message-components#component-types
  COMPONENT_TYPES = {
    action_row: 1,
    button: 2,
    string_select: 3,
    # text_input: 4, # (defined in modal.rb)
    user_select: 5,
    role_select: 6,
    mentionable_select: 7,
    channel_select: 8
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
    # @param style [Symbol, Integer] The button's style type. See {BUTTON_STYLES}
    # @param label [String, nil] The text label for the button. Either a label or emoji must be provided.
    # @param emoji [#to_h, String, Integer] An emoji ID, or unicode emoji to attach to the button. Can also be a object
    #   that responds to `#to_h` which returns a hash in the format of `{ id: Integer, name: string }`.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param disabled [true, false] Whether this button is disabled and shown as greyed out.
    # @param url [String, nil] The URL, when using a link style button.
    def button(style:, label: nil, emoji: nil, custom_id: nil, disabled: nil, url: nil)
      style = BUTTON_STYLES[style] || style

      emoji = case emoji
              when Integer, String
                emoji.to_i.positive? ? { id: emoji } : { name: emoji }
              else
                emoji.to_h
              end

      @components << { type: COMPONENT_TYPES[:button], label: label, emoji: emoji, style: style, custom_id: custom_id, disabled: disabled, url: url }
    end

    # Add a select string to this action row.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param options [Array<Hash>] Options that can be selected in this menu. Can also be provided via the yielded builder.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param disabled [true, false, nil] Grey out the component to make it unusable.
    # @yieldparam builder [SelectMenuBuilder]
    def string_select(custom_id:, options: [], placeholder: nil, min_values: nil, max_values: nil, disabled: nil)
      builder = SelectMenuBuilder.new(custom_id, options, placeholder, min_values, max_values, disabled, select_type: :string_select)

      yield builder if block_given?

      @components << builder.to_h
    end

    alias_method :select_menu, :string_select

    # Add a select user to this action row.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param disabled [true, false, nil] Grey out the component to make it unusable.
    def user_select(custom_id:, placeholder: nil, min_values: nil, max_values: nil, disabled: nil)
      @components << SelectMenuBuilder.new(custom_id, [], placeholder, min_values, max_values, disabled, select_type: :user_select).to_h
    end

    # Add a select role to this action row.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param disabled [true, false, nil] Grey out the component to make it unusable.
    def role_select(custom_id:, placeholder: nil, min_values: nil, max_values: nil, disabled: nil)
      @components << SelectMenuBuilder.new(custom_id, [], placeholder, min_values, max_values, disabled, select_type: :role_select).to_h
    end

    # Add a select mentionable to this action row.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param disabled [true, false, nil] Grey out the component to make it unusable.
    def mentionable_select(custom_id:, placeholder: nil, min_values: nil, max_values: nil, disabled: nil)
      @components << SelectMenuBuilder.new(custom_id, [], placeholder, min_values, max_values, disabled, select_type: :mentionable_select).to_h
    end

    # Add a select channel to this action row.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param disabled [true, false, nil] Grey out the component to make it unusable.
    def channel_select(custom_id:, placeholder: nil, min_values: nil, max_values: nil, disabled: nil)
      @components << SelectMenuBuilder.new(custom_id, [], placeholder, min_values, max_values, disabled, select_type: :channel_select).to_h
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:action_row], components: @components }
    end
  end

  # A builder to assist in adding options to select menus.
  class SelectMenuBuilder
    # @!visibility hidden
    def initialize(custom_id, options = [], placeholder = nil, min_values = nil, max_values = nil, disabled = nil, select_type: :string_select)
      @custom_id = custom_id
      @options = options
      @placeholder = placeholder
      @min_values = min_values
      @max_values = max_values
      @disabled = disabled
      @select_type = select_type
    end

    # Add an option to this select menu.
    # @param label [String] The title of this option.
    # @param value [String] The value that this option represents.
    # @param description [String, nil] An optional description of the option.
    # @param emoji [#to_h, String, Integer] An emoji ID, or unicode emoji to attach to the button. Can also be a object
    #   that responds to `#to_h` which returns a hash in the format of `{ id: Integer, name: string }`.
    # @param default [true, false, nil] Whether this is the default selected option.
    def option(label:, value:, description: nil, emoji: nil, default: nil)
      emoji = case emoji
              when Integer, String
                emoji.to_i.positive? ? { id: emoji } : { name: emoji }
              else
                emoji.to_h
              end

      @options << { label: label, value: value, description: description, emoji: emoji, default: default }
    end

    # @!visibility private
    def to_h
      {
        type: COMPONENT_TYPES[@select_type],
        options: @options,
        placeholder: @placeholder,
        min_values: @min_values,
        max_values: @max_values,
        custom_id: @custom_id,
        disabled: @disabled
      }
    end
  end

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
    @rows.map(&:to_h)
  end
end
