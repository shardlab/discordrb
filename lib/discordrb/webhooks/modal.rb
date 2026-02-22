# frozen_string_literal: true

# Modal component builder.
class Discordrb::Webhooks::Modal
  # A mapping of names to types of components usable in a modal.
  COMPONENT_TYPES = {
    action_row: 1,
    string_select: 3,
    text_input: 4,
    user_select: 5,
    role_select: 6,
    mentionable_select: 7,
    channel_select: 8,
    text_display: 10,
    label: 18,
    file_upload: 19,
    radio_group: 21,
    checkbox_group: 22,
    checkbox: 23
  }.freeze

  # Builder for radio and checkbox groups.
  class GroupBuilder
    # @!visibility private
    def initialize(type, custom_id, id, options = [], required = nil, min_values = nil, max_values = nil)
      @id = id
      @type = type
      @custom_id = custom_id
      @options = options
      @required = required
      @min_values = min_values
      @max_values = max_values
    end

    # Add a checkbox component to the group.
    # @param value [String] The value that the checkbox represents.
    # @param label [String] The primary text of the checkbox.
    # @param description [String, nil] The description of the checkbox.
    # @param default [true, false, nil] Whether or not the checkbox should be checked by default.
    def checkbox(value:, label:, description: nil, default: nil)
      raise "Cannot add a checkbox to a #{@type}" unless @type == :checkbox_group

      @options << { value: value, label: label, description: description, default: default }
    end

    # Add a radio button component to the group.
    # @param value [String] The value that the radio button represents.
    # @param label [String] The primary text of the radio button.
    # @param description [String, nil] The description of the radio button.
    # @param default [true, false, nil] Whether or not the radio button should be selected by default.
    def radio_button(value:, label:, description: nil, default: nil)
      raise "Cannot add a radio button to a #{@type}" unless @type == :radio_group

      @options << { value: value, label: label, description: description, default: default }
    end

    alias_method :button, :radio_button

    # @!visibility private
    def to_h
      {
        id: @id,
        type: COMPONENT_TYPES[@type],
        custom_id: @custom_id,
        options: @options.map(&:to_h),
        required: @required,
        min_values: @min_values,
        max_values: @max_values
      }.compact
    end
  end

  # This builder is used when adding a label component to a modal.
  class LabelBuilder
    # A mapping of text input styles to symbol names. `short` is a single line where `paragraph` is a block.
    TEXT_INPUT_STYLES = {
      short: 1,
      paragraph: 2
    }.freeze

    # Create a label component.
    # @param label [String, nil] The label of the label component. This
    #   field should always be passed, and will be required in 4.0.
    # @param id [Integer, nil] The unique 32-bit ID of the label component.
    # @param description [String, nil] The description of the label component.
    # @yieldparam builder [LabelBuilder] Yields the initialized label component.
    def initialize(label: nil, id: nil, description: nil)
      @id = id
      @label = label
      @description = description

      yield self if block_given?
    end

    # Add a text input to the label component.
    # @param style [Symbol, Integer] The text input's style type. See {TEXT_INPUT_STYLES}
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #  There is a limit of 100 characters to each custom_id.
    # @param id [Integer] The integer ID for this component. This is not to be confused with custom_id.
    # @param min_length [Integer, nil] The minimum input length for a text input, min 0, max 4000.
    # @param max_length [Integer, nil] The maximum input length for a text input, min 1, max 4000.
    # @param required [true, false, nil] Whether this component is required to be filled, default true.
    # @param value [String, nil] A pre-filled value for this component, max 4000 characters.
    # @param placeholder [String, nil] Custom placeholder text if the input is empty, max 100 characters
    # @param label [String, nil] This parameter is deprecated and will be removed soon. Please pass this argument to {LabelBuilder#initialize} instead.
    def text_input(style:, custom_id:, id: nil, min_length: nil, max_length: nil, required: nil, value: nil, placeholder: nil, label: nil)
      @label = label unless label.nil?

      @component = {
        id: id,
        style: TEXT_INPUT_STYLES[style] || style,
        custom_id: custom_id,
        type: COMPONENT_TYPES[:text_input],
        min_length: min_length,
        max_length: max_length,
        required: required,
        value: value,
        placeholder: placeholder
      }.compact
    end

    # Add a string select menu to the label component.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer, nil] The unique 32-bit ID of the string select. This is not to be confused with the `custom_id`.
    # @param options [Array<Hash>] Options that can be selected in this menu. Can also be provided via the yielded builder.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param required [true, false, nil] Whether a value must be selected for the component.
    # @yieldparam builder [SelectMenuBuilder] The select menu builder is yielded to allow for the modification of attributes.
    def string_select(custom_id:, id: nil, options: [], placeholder: nil, min_values: nil, max_values: nil, required: nil)
      builder = Discordrb::Webhooks::View::SelectMenuBuilder.new(custom_id, options, placeholder, min_values, max_values, nil, select_type: :string_select, id: id, required: required)

      yield builder if block_given?

      @component = builder.to_h
    end

    alias_method :select_menu, :string_select

    # Add a select user to the label component.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer, nil] The unique 32-bit ID of the user select. This is not to be confused with the `custom_id`.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param required [true, false, nil] Whether a value must be selected for the component.
    def user_select(custom_id:, id: nil, placeholder: nil, min_values: nil, max_values: nil, required: nil)
      @component = Discordrb::Webhooks::View::SelectMenuBuilder.new(custom_id, [], placeholder, min_values, max_values, nil, select_type: :user_select, id: id, required: required).to_h
    end

    # Add a select role to the label component.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer, nil] The unique 32-bit ID of the role select. This is not to be confused with the `custom_id`.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param required [true, false, nil] Whether a value must be selected for the component.
    def role_select(custom_id:, id: nil, placeholder: nil, min_values: nil, max_values: nil, required: nil)
      @component = Discordrb::Webhooks::View::SelectMenuBuilder.new(custom_id, [], placeholder, min_values, max_values, nil, select_type: :role_select, id: id, required: required).to_h
    end

    # Add a select mentionable to the label component.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer, nil] The unique 32-bit ID of the mentionable select. This is not to be confused with the `custom_id`.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param required [true, false, nil] Whether a value must be selected for the component.
    def mentionable_select(custom_id:, id: nil, placeholder: nil, min_values: nil, max_values: nil, required: nil)
      @component = Discordrb::Webhooks::View::SelectMenuBuilder.new(custom_id, [], placeholder, min_values, max_values, nil, select_type: :mentionable_select, id: id, required: required).to_h
    end

    # Add a select channel to the label component.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer, nil] The unique 32-bit ID of the channel select. This is not to be confused with the `custom_id`.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param required [true, false, nil] Whether a value must be selected for the component.
    # @param types [Array<Symbol, Integer>, nil] The channel types to include in the select menu.
    def channel_select(custom_id:, id: nil, placeholder: nil, min_values: nil, max_values: nil, required: nil, types: nil)
      builder = Discordrb::Webhooks::View::SelectMenuBuilder.new(custom_id, [], placeholder, min_values, max_values, nil, select_type: :channel_select, id: id, required: required).to_h

      builder[:channel_types] = types.map { |type| Discordrb::Channel::TYPES[type] || type } if types

      @component = builder
    end

    # Add a file upload component to the label component.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer, nil] The unique 32-bit ID of the file upload component. This is not to be confused with the `custom_id`.
    # @param min_values [Integer, nil] The minimum amount of files a user must upload.
    # @param max_values [Integer, nil] The maximum amount of files a user has to upload.
    # @param required [true, false, nil] Whether or not a file must be uploaded to the component.
    def file_upload(custom_id:, id: nil, min_values: nil, max_values: nil, required: nil)
      @component = { type: COMPONENT_TYPES[:file_upload], custom_id: custom_id, id: id, min_values: min_values, max_values: max_values, required: required }.compact
    end

    # Add a standalone checkbox component to the label component.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer, nil] The unique 32-bit ID of the checkbox component. This is not to be confused with the `custom_id`.
    # @param default [true, false, nil] Whether or not the checkbox is checked by default.
    def checkbox(custom_id:, id: nil, default: false)
      @component = { type: COMPONENT_TYPES[:checkbox], custom_id: custom_id, id: id, default: default }.compact
    end

    # Add a group of radio buttons to the label component.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer, nil] The unique 32-bit ID of the radio group component. This is not to be confused with the `custom_id`.
    # @param buttons [Array<Hash>] Radio buttons for the group. Can also be provided via the yielded builder.
    # @param required [true, false, nil] Whether or not a radio button in the group must be selected.
    def radio_group(custom_id:, id: nil, buttons: [], required: nil)
      builder = GroupBuilder.new(:radio_group, custom_id, id, buttons, required)

      yield builder if block_given?

      @component = builder.to_h
    end

    # Add a group of checkboxes to the label component.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer, nil] The unique 32-bit ID of the checkbox group component. This is not to be confused with the `custom_id`.
    # @param checkboxes [Array<Hash>] Checkboxes for the group. Can also be provided via the yielded builder.
    # @param min_values [Integer, nil] The minimum number of checkboxes a user must check.
    # @param max_values [Integer, nil] The maximum number of checkboxes a user is allowed to check.
    # @param required [true, false, nil] Whether or not a checkbox must be checked.
    def checkbox_group(custom_id:, id: nil, checkboxes: [], min_values: nil, max_values: nil, required: nil)
      builder = GroupBuilder.new(:checkbox_group, custom_id, id, checkboxes, required, min_values, max_values)

      yield builder if block_given?

      @component = builder.to_h
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:label], label: @label, description: @description, component: @component }.compact
    end
  end

  # @!visibility private
  def initialize
    @components = []

    yield self if block_given?
  end

  # @!visibility private
  def to_a
    @components.map(&:to_h)
  end

  # Add a label component to the view.
  # @see LabelBuilder#initialize
  def label(...)
    @components << LabelBuilder.new(...)
  end

  # Add a text display component to the view.
  # @see Webhooks::View::TextDisplayBuilder#initialize
  def text_display(...)
    @components << Discordrb::Webhooks::View::TextDisplayBuilder.new(...)
  end

  # @deprecated Please use {#label} instead.
  alias_method :row, :label

  # @deprecated This alias will be removed in future releases.
  RowBuilder = LabelBuilder
end
