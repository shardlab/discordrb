# frozen_string_literal: true

# Modal component builder.
class Discordrb::Webhooks::Modal
  # A mapping of names to types of components usable in a modal.
  COMPONENT_TYPES = {
    action_row: 1,
    text_input: 4
  }.freeze

  # This builder is used when constructing an ActionRow. All current components must be within an action row, but this can
  # change in the future. A message can have 5 action rows, each action row can hold a weight of 5. Buttons have a weight of 1,
  # and dropdowns have a weight of 5.
  class RowBuilder
    # A mapping of short names to types of input styles. `short` is a single line where `paragraph` is a block.
    TEXT_INPUT_STYLES = {
      short: 1,
      paragraph: 2
    }.freeze

    # @!visibility private
    def initialize
      @components = []
    end

    # Add a text input to this action row.
    # @param style [Symbol, Integer] The text input's style type. See {TEXT_INPUT_STYLES}
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #  There is a limit of 100 characters to each custom_id.
    # @param label [String, nil] The text label for the field.
    # @param min_length [Integer, nil] The minimum input length for a text input, min 0, max 4000.
    # @param max_length [Integer, nil] The maximum input length for a text input, min 1, max 4000.
    # @param required [true, false, nil] Whether this component is required to be filled, default true.
    # @param value [String, nil] A pre-filled value for this component, max 4000 characters.
    # @param placeholder [String, nil] Custom placeholder text if the input is empty, max 100 characters
    def text_input(style:, custom_id:, label: nil, min_length: nil, max_length: nil, required: nil, value: nil, placeholder: nil)
      style = TEXT_INPUT_STYLES[style] || style

      @components << {
        style: style,
        custom_id: custom_id,
        type: COMPONENT_TYPES[:text_input],
        label: label,
        min_length: min_length,
        max_length: max_length,
        required: required,
        value: value,
        placeholder: placeholder
      }
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:action_row], components: @components }
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
