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

  # Possible seperator size names and values.
  SEPERATOR_SIZES = {
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
    seperator: 14,
    container: 17
    # label: 18, # (defined in modal.rb)
    # file_upload: 19, (defined in modal.rb)
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
    # @param id [Integer] The integer ID for this component. This is not to be confused with custom_id.
    # @param label [String, nil] The text label for the button. Either a label or emoji must be provided.
    # @param emoji [#to_h, String, Integer] An emoji ID, or unicode emoji to attach to the button. Can also be a object
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
    # @param id [Integer] The integer ID for this component. This is not to be confused with custom_id.
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
    # @param id [Integer] The integer ID for this component. This is not to be confused with custom_id.
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
    # @param id [Integer] The integer ID for this component. This is not to be confused with custom_id.
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
    # @param id [Integer] The integer ID for this component. This is not to be confused with custom_id.
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
    # @param id [Integer] The integer ID for this component. This is not to be confused with custom_id.
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
      { id: @id, type: COMPONENT_TYPES[:action_row], components: @components }.compact
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
    # @param emoji [#to_h, String, Integer] An emoji ID, or unicode emoji to attach to the button. Can also be a object
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

  # A text display component allows you to send text content.
  class TextDisplayBuilder
    # @overload id=(value)
    #   @param value [Integer, nil] The 32-bit ID of the text display component.
    #   @return [void]
    attr_writer :id

    # @overload text=(value)
    #   @param value [String] The text content of the text display component.
    #   @return [void]
    attr_writer :text

    # @!visibility private
    def initialize(text:, id: nil)
      @id = id
      @content = text

      yield self if block_given?
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:text_display], content: @content, id: @id }.compact
    end
  end

  # A seperator allows you to add seperation between components.
  class SeperatorBuilder
    # @overload id=(value)
    #   @param value [Integer, nil] The 32-bit ID of the seperator component.
    #   @return [void]
    attr_writer :id

    # @overload divider=(value)
    #   @param value [true, false] Whether the seperator should appear as a visual divider.
    #   @return [void]
    attr_writer :divider

    # @overload spacing=(value)
    #   @param value [Symbol, Integer] The size of the seperator's padding. See {SEPERATOR_SIZES}.
    #   @return [void]
    attr_writer :spacing

    # @!visibility private
    def initialize(divider:, spacing: nil, id: nil)
      @id = id
      @spacing = spacing
      @divider = divider
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:seperator], spacing: SEPERATOR_SIZES[@spacing] || @spacing, divider: @divider, id: @id }.compact
    end
  end

  # A file component lets you send a file via an attachment://<filename> reference.
  class FileBuilder
    # @overload id=(value)
    #   @param value [Integer, nil] The new 32-bit ID of the file component.
    #   @return [void]
    attr_writer :id

    # @overload url=(value)
    #   @param value [String] The `attachment://<filename>` reference of the file component.
    #   @return [void]
    attr_writer :url

    # @overload spoiler=(value)
    #   @param value [true, false] Whether the file component should have a spoiler label.
    #   @return [void]
    attr_writer :spoiler

    # @!visibility private
    def initialize(url:, spoiler: false, id: nil)
      @id = id
      @url = url
      @spoiler = spoiler

      yield self if block_given?
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:file], id: @id, spoiler: @spoiler, file: { url: @url } }.compact
    end
  end

  # A media gallery component lets you group together images, videos, or GIFs in a gallery grid.
  class MediaGalleryBuilder
    # @overload id=(value)
    #   @param value [Integer, nil] The 32-bit ID of the media gallery component.
    #   @return [void]
    attr_writer :id

    # @!visibility private
    def initialize(id: nil)
      @id = id
      @items = []

      yield self if block_given?
    end

    # Add a gallery item to this media gallery.
    # @param url [String] The URL to the gallery item.
    # @param description [String, nil] The description of the gallery item.
    # @param spoiler [true, false] Whether the gallery item should have a spoiler label.
    def gallery_item(url:, description: nil, spoiler: false)
      @items << { media: { url: url }, description: description, spoiler: spoiler }.compact
    end

    alias_method :item, :gallery_item

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:media_gallery], items: @items }
    end
  end

  # A section allows you to group together text display components, and pair them with an accessory.
  class SectionBuilder
    # @overload id=(value)
    #   @param value [Integer, nil] The 32-bit ID of the section component.
    #   @return [void]
    attr_writer :id

    # @!visibility private
    def initialize(id: nil)
      @id = id
      @accessory = nil
      @components = []

      yield self if block_given?
    end

    # Add a text display component to this section.
    # @yieldparam builder [TextDisplayBuilder] The text display builder is yielded to allow for modification of attributes.
    def text_display(...)
      @components << TextDisplayBuilder.new(...)
    end

    # Set the thumbnail for this section. This is mutually exclusive with {#button}.
    # @param url [String] The URL to the thumbnail image.
    # @param id [Integer, nil] The 32-bit ID of the thumbnail component.
    # @param description [String, nil] The description of the thumbnail image.
    # @param spoiler [true, false] Whether the thumbnail image should have a spoiler label.
    def thumbnail(url:, id: nil, description: nil, spoiler: false)
      @accessory = {
        type: COMPONENT_TYPES[:thumbnail],
        id: id,
        media: { url: url },
        description: description,
        spoiler: spoiler
      }.compact
    end

    # Set the button for this section. This is mutually exclusive with {#thumbnail}.
    # @param style [Symbol, Integer] The button's style type. See {BUTTON_STYLES}
    # @param id [Integer] Integer ID for this component. This is not to be confused with custom_id.
    # @param label [String, nil] The text label for the button. Either a label or emoji must be provided.
    # @param emoji [#to_h, String, Integer] An emoji ID, or unicode emoji to attach to the button. Can also be a object
    # that responds to `#to_h` which returns a hash in the format of `{ id: Integer, name: string }`.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    # There is a limit of 100 characters to each custom_id.
    # @param disabled [true, false] Whether this button is disabled and shown as greyed out.
    # @param url [String, nil] The URL, when using a link style button.
    def button(style:, id: nil, label: nil, emoji: nil, custom_id: nil, disabled: nil, url: nil)
      emoji = case emoji
              when Integer, String
                emoji.to_i.positive? ? { id: emoji } : { name: emoji }
              else
                emoji&.to_h
              end

      @accessory = {
        type: COMPONENT_TYPES[:button],
        id: id,
        label: label,
        emoji: emoji,
        style: BUTTON_STYLES[style] || style,
        custom_id: custom_id,
        disabled: disabled,
        url: url
      }.compact
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:section], components: @components.map(&:to_h), accessory: @accessory }.compact
    end
  end

  # This builder can be used to construct a container. These are similar to embeds.
  class ContainerBuilder
    # @overload id=(value)
    #   @param value [Integer, nil] The 32-bit ID of the container component.
    #   @return [void]
    attr_writer :id

    # @overload colour=(value)
    #   @param value [Integer, String, ColourRGB, nil] The accent colour of the container component.
    #   @return [void]
    attr_writer :colour
    alias_method :color=, :colour=

    # @overload spoiler=(value)
    #   @param value [true, false] Whether the container component should have a spoiler label.
    #   @return [void]
    attr_writer :spoiler

    # @!visibility private
    def initialize(id: nil, color: nil, colour: nil, spoiler: nil)
      @id = id
      @colour = colour || color
      @spoiler = spoiler
      @components = []

      yield self if block_given?
    end

    # Add a text display component to this container.
    # @yieldparam builder [TextDisplayBuilder] The text display builder is yielded to allow for the modification of attributes.
    def text_display(...)
      @components << TextDisplayBuilder.new(...)
    end

    # Add a section component to this container.
    # @yieldparam builder [SectionBuilder] The section builder is yielded to allow for the modification of attributes.
    def section(...)
      @components << SectionBuilder.new(...)
    end

    # Add a media gallery component to this container.
    # @yieldparam builder [MediaGalleryBuilder] The media gallery builder is yielded to allow for the modification of attributes.
    def media_gallery(...)
      @components << MediaGalleryBuilder.new(...)
    end

    # Add a seperator component to this container.
    # @yieldparam builder [SectionBuilder] The section builder is yielded to allow for the modification of attributes.
    def seperator(...)
      @components << SeperatorBuilder.new(...)
    end

    # Add a file component to this container.
    # @yieldparam builder [FileBuilder] The file builder is yielded to allow for the modification of attributes.
    def file(...)
      @components << FileBuilder.new(...)
    end

    # Add an action row component to this container.
    # @yieldparam builder [RowBuilder] the action row builder is yielded to allow for the addition of components.
    def row(...)
      @components << RowBuilder.new(...)
    end

    # @!visibility private
    def to_h
      {
        type: COMPONENT_TYPES[:container],
        accent_color: process_colour(@colour),
        spoiler: @spoiler,
        components: @components.map(&:to_h)
      }.compact
    end

    private

    # @!visibility private
    # @note for internal use only
    # Process the color into an integer value.
    def process_colour(value)
      case value
      when Array
        (value[0] << 16) | (value[1] << 8) | value[2]
      when String
        value.delete('#').to_i(16)
      else
        value&.to_i
      end
    end
  end

  # @!visibility private
  attr_reader :components

  # @!visibility private
  def initialize
    @components = []

    yield self if block_given?
  end

  # Add an action row component to this view.
  # @yieldparam builder [RowBuilder] the action row builder is yielded to allow for the modification of attributes.
  def row(...)
    @components << RowBuilder.new(...)
  end

  # Add a text display component to this view.
  # @yieldparam builder [TextDisplayBuilder] The text display builder is yielded to allow for the modification of attributes.
  def text_display(...)
    @components << TextDisplayBuilder.new(...)
  end

  # Add a section component to this view.
  # @yieldparam builder [SectionBuilder] The section builder is yielded to allow for the modification of attributes.
  def section(...)
    @components << SectionBuilder.new(...)
  end

  # Add a media gallery component to this view.
  # @yieldparam builder [MediaGalleryBuilder] The media gallery builder is yielded to allow for the modification of attributes.
  def media_gallery(...)
    @components << MediaGalleryBuilder.new(...)
  end

  # Add a seperator component to this view.
  # @yieldparam builder [SectionBuilder] The section builder is yielded to allow for the modification of attributes.
  def seperator(...)
    @components << SeperatorBuilder.new(...)
  end

  # Add a file component to this view.
  # @yieldparam builder [FileBuilder] The file builder is yielded to allow for the modification of attributes.
  def file(...)
    @components << FileBuilder.new(...)
  end

  # Add a container to this view.
  # @yieldparam builder [ContainerBuilder] The container builder is yielded to allow for for modification of attributes.
  def container(...)
    @components << ContainerBuilder.new(...)
  end

  # @!visibility private
  # @return [Array<Hash>]
  def to_a
    @components.map(&:to_h)
  end

  # @!visibility private
  # @return [Array<RowBuilder>]
  def rows
    @components.select { |component| component.is_a?(RowBuilder) }
  end
end
