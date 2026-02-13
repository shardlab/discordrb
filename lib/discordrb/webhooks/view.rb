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

  # Possible separator size names and values.
  SEPARATOR_SIZES = {
    small: 1,
    large: 2
  }.freeze

  # Component types.
  # @see https://discord.com/developers/docs/components/reference#component-object-component-types
  COMPONENT_TYPES = {
    action_row: 1,
    button: 2,
    string_select: 3,
    # text_input: 4, # (defined in modal.rb)
    user_select: 5,
    role_select: 6,
    mentionable_select: 7,
    channel_select: 8,
    section: 9,
    text_display: 10,
    thumbnail: 11,
    media_gallery: 12,
    file: 13,
    separator: 14,
    container: 17
    # label: 18, # (defined in modal.rb)
    # file_upload: 19, (defined in modal.rb)
    # radio_group: 21, (defined in modal.rb)
    # checkbox_group: 22, (defined in modal.rb)
    # checkbox: 23 (defined in modal.rb)
  }.freeze

  # This builder is used when constructing an ActionRow. Button and select menu components must be within an action row, but this can
  # change in the future. A message can have 10 action rows, each action row can hold a weight of 5. Buttons have a weight of 1,
  # and dropdowns have a weight of 5.
  class RowBuilder
    # @!visibility private
    def initialize(id: nil)
      @id = id
      @components = []

      yield self if block_given?
    end

    # Add a button to this action row.
    # @param style [Symbol, Integer] The button's style type. See {BUTTON_STYLES}
    # @param id [Integer, nil] The unique 32-bit ID of the button component. This is not to be confused with the `custom_id`.
    # @param label [String, nil] The text label for the button. Either a label or emoji must be provided.
    # @param emoji [#to_h, String, Integer] An emoji ID, or unicode emoji to attach to the button. Can also be an object
    #   that responds to `#to_h` which returns a hash in the format of `{ id: Integer, name: string }`.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param disabled [true, false] Whether this button is disabled and shown as greyed out.
    # @param url [String, nil] The URL, when using a link style button.
    def button(style:, id: nil, label: nil, emoji: nil, custom_id: nil, disabled: nil, url: nil)
      style = BUTTON_STYLES[style] || style

      emoji = case emoji
              when Integer, String
                emoji.to_i.positive? ? { id: emoji } : { name: emoji }
              else
                emoji&.to_h
              end

      @components << { type: COMPONENT_TYPES[:button], id: id, label: label, emoji: emoji, style: style, custom_id: custom_id, disabled: disabled, url: url }.compact
    end

    # Add a string select to this action row.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer, nil] The unique 32-bit ID of the string select. This is not to be confused with the `custom_id`.
    # @param options [Array<Hash>] Options that can be selected in this menu. Can also be provided via the yielded builder.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param disabled [true, false, nil] Grey out the component to make it unusable.
    # @yieldparam builder [SelectMenuBuilder]
    def string_select(custom_id:, options: [], id: nil, placeholder: nil, min_values: nil, max_values: nil, disabled: nil)
      builder = SelectMenuBuilder.new(custom_id, options, placeholder, min_values, max_values, disabled, select_type: :string_select, id: id)

      yield builder if block_given?

      @components << builder.to_h
    end

    alias_method :select_menu, :string_select

    # Add a select user to this action row.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer, nil] The unique 32-bit ID of the user select. This is not to be confused with the `custom_id`.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param disabled [true, false, nil] Grey out the component to make it unusable.
    def user_select(custom_id:, id: nil, placeholder: nil, min_values: nil, max_values: nil, disabled: nil)
      @components << SelectMenuBuilder.new(custom_id, [], placeholder, min_values, max_values, disabled, select_type: :user_select, id: id).to_h
    end

    # Add a select role to this action row.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer, nil] The unique 32-bit ID of the role select. This is not to be confused with the `custom_id`.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param disabled [true, false, nil] Grey out the component to make it unusable.
    def role_select(custom_id:, id: nil, placeholder: nil, min_values: nil, max_values: nil, disabled: nil)
      @components << SelectMenuBuilder.new(custom_id, [], placeholder, min_values, max_values, disabled, select_type: :role_select, id: id).to_h
    end

    # Add a select mentionable to this action row.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer, nil] The unique 32-bit ID of the mentionable select. This is not to be confused with the `custom_id`.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param disabled [true, false, nil] Grey out the component to make it unusable.
    def mentionable_select(custom_id:, id: nil, placeholder: nil, min_values: nil, max_values: nil, disabled: nil)
      @components << SelectMenuBuilder.new(custom_id, [], placeholder, min_values, max_values, disabled, select_type: :mentionable_select, id: id).to_h
    end

    # Add a select channel to this action row.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer, nil] The unique 32-bit ID of the channel select. This is not to be confused with the `custom_id`.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param disabled [true, false, nil] Grey out the component to make it unusable.
    # @param types [Array<Symbol, Integer>, nil] The channel types to include in the select menu.
    def channel_select(custom_id:, id: nil, placeholder: nil, min_values: nil, max_values: nil, disabled: nil, types: nil)
      builder = SelectMenuBuilder.new(custom_id, [], placeholder, min_values, max_values, disabled, select_type: :channel_select, id: id).to_h

      builder[:channel_types] = types.map { |type| Discordrb::Channel::TYPES[type] || type } if types

      @components << builder
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:action_row], id: @id, components: @components }.compact
    end
  end

  # A builder to assist in adding options to select menus.
  class SelectMenuBuilder
    # @!visibility hidden
    def initialize(custom_id, options = [], placeholder = nil, min_values = nil, max_values = nil, disabled = nil, select_type: :string_select, id: nil, required: nil)
      @id = id
      @custom_id = custom_id
      @options = options
      @placeholder = placeholder
      @min_values = min_values
      @max_values = max_values
      @disabled = disabled
      @select_type = select_type
      @required = required
    end

    # Add an option to this select menu.
    # @param label [String] The title of this option.
    # @param value [String] The value that this option represents.
    # @param description [String, nil] An optional description of the option.
    # @param emoji [#to_h, String, Integer] An emoji ID, or unicode emoji to attach to the button. Can also be an object
    #   that responds to `#to_h` which returns a hash in the format of `{ id: Integer, name: string }`.
    # @param default [true, false, nil] Whether this is the default selected option.
    def option(label:, value:, description: nil, emoji: nil, default: nil)
      emoji = case emoji
              when Integer, String
                emoji.to_i.positive? ? { id: emoji } : { name: emoji }
              else
                emoji&.to_h
              end

      @options << { label: label, value: value, description: description, emoji: emoji, default: default }
    end

    # @!visibility private
    def to_h
      {
        type: COMPONENT_TYPES[@select_type],
        id: @id,
        options: @options,
        placeholder: @placeholder,
        min_values: @min_values,
        max_values: @max_values,
        custom_id: @custom_id,
        disabled: @disabled,
        required: @required
      }.compact
    end
  end

  # A text display component allows you to send message content.
  class TextDisplayBuilder
    # Create a text display component.
    # @param content [String] The content of the text display component.
    # @param id [Integer, nil] The unique 32-bit ID of the text display component.
    def initialize(content:, id: nil)
      @id = id
      @content = content
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:text_display], id: @id, content: @content }.compact
    end
  end

  # A separator allows you to add a barrier between components.
  class SeparatorBuilder
    # Create a separator component.
    # @param divider [true, false] Whether or not the separator should act as a visible barrier.
    # @param id [Integer, nil] The unique 32-bit ID of the separator component.
    # @param spacing [Symbol, Integer] The size of the separator component's padding. See {SEPARATOR_SIZES}.
    def initialize(divider:, id: nil, spacing: nil)
      @id = id
      @divider = divider
      @spacing = SEPARATOR_SIZES[spacing] || spacing
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:separator], id: @id, divider: @divider, spacing: @spacing }.compact
    end
  end

  # A file component lets you send a file via an attachment://<filename> reference.
  class FileBuilder
    # Create a file component.
    # @param url [String] An `attachment://<filename>` reference to the attached file.
    # @param id [Integer, nil] The unique 32-bit ID of the file component.
    # @param spoiler [true, false] Whether or not to apply a spoiler label to the file.
    def initialize(url:, id: nil, spoiler: false)
      @id = id
      @file = { url: }
      @spoiler = spoiler
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:file], id: @id, spoiler: @spoiler, file: @file }.compact
    end
  end

  # A media gallery component is a gallery grid.
  class MediaGalleryBuilder
    # Create a media gallery component.
    # @param id [Integer, nil] The unique 32-bit ID of the media gallery component.
    # @yieldparam builder [MediaGalleryBuilder] Yields the initialized media gallery component.
    def initialize(id: nil)
      @id = id
      @items = []

      yield self if block_given?
    end

    # Add a gallery item to the media gallery component.
    # @param url [String] The URL to the gallery item's media.
    # @param description [String, nil] The description of the gallery item.
    # @param spoiler [true, false] Whether or not to apply a spoiler label to the gallery item.
    def item(url:, description: nil, spoiler: false)
      @items << { media: { url: }, description: description, spoiler: spoiler }.compact
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:media_gallery], id: @id, items: @items }.compact
    end
  end

  # A section allows you to group together an accessory with text display components.
  class SectionBuilder
    # Create a section component.
    # @param id [Integer, nil] The unique 32-bit ID of the section component.
    # @yieldparam builder [SectionBuilder] Yields the initialized section component.
    def initialize(id: nil)
      @id = id
      @accessory = nil
      @components = []

      yield self if block_given?
    end

    # Add a text display component to this section.
    # @see TextDisplayBuilder#initialize
    def text_display(...)
      @components << TextDisplayBuilder.new(...)
    end

    # Set the thumbnail for the section. This is mutually exclusive with {#button}.
    # @param url [String] The URL to the thumbnail image.
    # @param id [Integer, nil] The unique 32-bit ID of the thumbnail component.
    # @param description [String, nil] The description of the thumbnail.
    # @param spoiler [true, false] Whether or not to apply a spoiler label to the thumbnail.
    def thumbnail(url:, id: nil, description: nil, spoiler: false)
      @accessory = { type: COMPONENT_TYPES[:thumbnail], id: id, media: { url: }, description: description, spoiler: spoiler }.compact
    end

    # Set the button for the section. This is mutually exclusive with {#thumbnail}.
    # @param style [Symbol, Integer] The button's style type. See {BUTTON_STYLES}
    # @param id [Integer, nil] The unique 32-bit ID of the button component. This is not to be confused with the `custom_id`.
    # @param label [String, nil] The text label for the button. Either a label or emoji must be provided.
    # @param emoji [#to_h, String, Integer] An emoji ID, or unicode emoji to attach to the button. Can also be an object
    # that responds to `#to_h` which returns a hash in the format of `{ id: Integer, name: string }`.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    # There is a limit of 100 characters to each custom_id.
    # @param disabled [true, false] Whether this button is disabled and shown as greyed out.
    # @param url [String, nil] The URL, when using a link style button.
    def button(style:, id: nil, label: nil, emoji: nil, custom_id: nil, disabled: nil, url: nil)
      style = BUTTON_STYLES[style] || style

      emoji = case emoji
              when Integer, String
                emoji.to_i.positive? ? { id: emoji } : { name: emoji }
              else
                emoji&.to_h
              end

      @accessory = { type: COMPONENT_TYPES[:button], id: id, label: label, emoji: emoji, style: style, custom_id: custom_id, disabled: disabled, url: url }.compact
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:section], id: @id, components: @components.map(&:to_h), accessory: @accessory }.compact
    end
  end

  # This builder can be used to construct a container. These are similar to embeds.
  class ContainerBuilder
    # Create a container component.
    # @param id [Integer, nil] The unique 32-bit ID of the container component.
    # @param colour [Array, Integer, String, ColourRGB, nil] The accent colour of the container
    #   component. This argument can be passed via the American spelling (`color:`) as well.
    # @param spoiler [true, false] Whether or not to apply a spoiler label to the container component.
    # @yieldparam builder [ContainerBuilder] Yields the initialized container component.
    def initialize(id: nil, color: nil, colour: nil, spoiler: false)
      @id = id
      @spoiler = spoiler
      @components = []
      self.colour = (colour || color)

      yield self if block_given?
    end

    # Add a row component to the container.
    # @see RowBuilder#initialize
    def row(...)
      @components << RowBuilder.new(...)
    end

    # Add a file component to the container.
    # @see FileBuilder#initialize
    def file(...)
      @components << FileBuilder.new(...)
    end

    alias_method :file_display, :file

    # Add a section component to the container.
    # @see SectionBuilder#initialize
    def section(...)
      @components << SectionBuilder.new(...)
    end

    # Add a separator component to the container.
    # @see SeparatorBuilder#initialize
    def separator(...)
      @components << SeparatorBuilder.new(...)
    end

    # Add a text display component to the container.
    # @see TextDisplayBuilder#initialize
    def text_display(...)
      @components << TextDisplayBuilder.new(...)
    end

    # Add a media gallery component to the container.
    # @see MediaGalleryBuilder#initialize
    def media_gallery(...)
      @components << MediaGalleryBuilder.new(...)
    end

    # Set the color of the container.
    # @param colour [Array, Integer, String, ColourRGB, nil] The accent colour of the container component, or `nil` to clear the accent colour.
    def colour=(colour)
      @colour = case colour
                when Array
                  (colour[0] << 16) | (colour[1] << 8) | colour[2]
                when String
                  colour.delete('#').to_i(16)
                else
                  colour&.to_i
                end
    end

    alias_method :color=, :colour=

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:container], id: @id, accent_color: @colour, spoiler: @spoiler, components: @components.map(&:to_h) }.compact
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

  # Add a row component to the view.
  # @see RowBuilder#initialize
  def row(...)
    @components << RowBuilder.new(...)
  end

  # Add a file component to the view.
  # @see FileBuilder#initialize
  def file(...)
    @components << FileBuilder.new(...)
  end

  alias_method :file_display, :file

  # Add a section component to the view.
  # @see SectionBuilder#initialize
  def section(...)
    @components << SectionBuilder.new(...)
  end

  # Add a separator component to the view.
  # @see SeparatorBuilder#initialize
  def separator(...)
    @components << SeparatorBuilder.new(...)
  end

  # Add a container component to the view.
  # @see ContainerBuilder#initialize
  def container(...)
    @components << ContainerBuilder.new(...)
  end

  # Add a text display component to the view.
  # @see TextDisplayBuilder#initialize
  def text_display(...)
    @components << TextDisplayBuilder.new(...)
  end

  # Add a media gallery component to the view.
  # @see MediaGalleryBuilder#initialize
  def media_gallery(...)
    @components << MediaGalleryBuilder.new(...)
  end
end
