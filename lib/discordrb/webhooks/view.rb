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
    channel_select: 8,
    section: 9,
    text_display: 10,
    thumbnail: 11,
    media_gallery: 12,
    file: 13,
    seperator: 14,
    container: 17
  }.freeze

  # Possible size values for seperators.
  # @see https://discord.com/developers/docs/interactions/message-components#seperator-sizes
  SEPERATOR_SIZES = {
    small: 1,
    large: 2
  }.freeze

  # This builder is used when constructing an ActionRow. Button and select menu components must be within an action row, but this can
  # change in the future. A message can have 10 action rows, each action row can hold a weight of 5. Buttons have a weight of 1,
  # and dropdowns have a weight of 5.
  class RowBuilder
    # @!visibility private
    def initialize(id = nil)
      @id = id
      @components = []
    end

    # Add a button to this action row.
    # @param style [Symbol, Integer] The button's style type. See {BUTTON_STYLES}
    # @param id [Integer] Integer ID for this component. This is not to be confused with custom_id.
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

    # Add a select string to this action row.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer] Integer ID for this component. This is not to be confused with custom_id.
    # @param options [Array<Hash>] Options that can be selected in this menu. Can also be provided via the yielded builder.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param disabled [true, false, nil] Grey out the component to make it unusable.
    # @yieldparam builder [SelectMenuBuilder]
    def string_select(custom_id:, options: [], id: nil, placeholder: nil, min_values: nil, max_values: nil, disabled: nil)
      builder = SelectMenuBuilder.new(custom_id, id, options, placeholder, min_values, max_values, disabled, select_type: :string_select)

      yield builder if block_given?

      @components << builder.to_h
    end

    alias_method :select_menu, :string_select

    # Add a select user to this action row.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer] Integer ID for this component. This is not to be confused with custom_id.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param disabled [true, false, nil] Grey out the component to make it unusable.
    def user_select(custom_id:, id: nil, placeholder: nil, min_values: nil, max_values: nil, disabled: nil)
      @components << SelectMenuBuilder.new(custom_id, id, [], placeholder, min_values, max_values, disabled, select_type: :user_select).to_h
    end

    # Add a select role to this action row.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer] Integer ID for this component. This is not to be confused with custom_id.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param disabled [true, false, nil] Grey out the component to make it unusable.
    def role_select(custom_id:, id: nil, placeholder: nil, min_values: nil, max_values: nil, disabled: nil)
      @components << SelectMenuBuilder.new(custom_id, id, [], placeholder, min_values, max_values, disabled, select_type: :role_select).to_h
    end

    # Add a select mentionable to this action row.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer] Integer ID for this component. This is not to be confused with custom_id.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param disabled [true, false, nil] Grey out the component to make it unusable.
    def mentionable_select(custom_id:, id: nil, placeholder: nil, min_values: nil, max_values: nil, disabled: nil)
      @components << SelectMenuBuilder.new(custom_id, id, [], placeholder, min_values, max_values, disabled, select_type: :mentionable_select).to_h
    end

    # Add a select channel to this action row.
    # @param custom_id [String] Custom IDs are used to pass state to the events that are raised from interactions.
    #   There is a limit of 100 characters to each custom_id.
    # @param id [Integer] Integer ID for this component. This is not to be confused with custom_id.
    # @param placeholder [String, nil] Default text to show when no entries are selected.
    # @param min_values [Integer, nil] The minimum amount of values a user must select.
    # @param max_values [Integer, nil] The maximum amount of values a user can select.
    # @param disabled [true, false, nil] Grey out the component to make it unusable.
    def channel_select(custom_id:, id: nil, placeholder: nil, min_values: nil, max_values: nil, disabled: nil)
      @components << SelectMenuBuilder.new(custom_id, id, [], placeholder, min_values, max_values, disabled, select_type: :channel_select).to_h
    end

    # @!visibility private
    def to_h
      { id: @id, type: COMPONENT_TYPES[:action_row], components: @components }.compact
    end
  end

  # A builder to assist in adding options to select menus.
  class SelectMenuBuilder
    # @!visibility hidden
    def initialize(custom_id, id = nil, options = [], placeholder = nil, min_values = nil, max_values = nil, disabled = nil, select_type: :string_select)
      @id = id
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
        disabled: @disabled
      }.compact
    end
  end

  # A text display component allows you to send text.
  class TextDisplayBuilder
    # Set the integer ID of this component.
    # @return [Integer, nil] integer ID of this component.
    attr_accessor :id

    # Set the content of this component.
    # @return [String] Content of this component.
    attr_accessor :text

    # @!visibility hidden
    def initialize(text = nil, id = nil)
      @text = text
      @id = id
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:text_display], content: @text, id: @id }.compact
    end
  end

  # A seperator allows you to seperate components.
  class SeperatorBuilder
    # Set the integer ID of this component.
    # @return [Integer, nil] integer ID of this component.
    attr_accessor :id

    # Whether this seperator is a divider.
    # @return [true, false] If this seperator is a divider.
    attr_accessor :divider

    # @!visibility hidden
    def initialize(divider = nil, spacing = nil, id = nil)
      @spacing = SEPERATOR_SIZES[spacing] || spacing
      @divider = divider
      @id = id
    end

    # Set the spacing of this builder.
    # @param space [Symbol, Integer] The space of the component. See {SEPERATOR_SIZES}.
    def spacing=(space)
      @spacing = SEPERATOR_SIZES[space] || space
    end

    # @!visibility hidden
    def to_h
      { type: COMPONENT_TYPES[:seperator],
        divider: @divider,
        spacing: @spacing,
        id: @id }.compact
    end
  end

  # A file component lets you send a file. Only attachment://<filename> references
  # are currently supported at the time of writing.
  class FileBuilder
    # If this file should be spoilered.
    # @return [true, false, nil] If this file is a spoiler or not.
    attr_accessor :spoiler

    # Set the integer ID of this component.
    # @return [Integer, nil] integer ID of this component.
    attr_accessor :id

    # @!visibility hidden
    def initialize(file = nil, spoiler = nil, id = nil)
      @id = id
      @file = { url: file }
      @spoiler = spoiler
    end

    # Set the file URL of this component.
    # @param file [String] attachment://<filename> reference.
    def file=(file)
      @file[:url] = file
    end

    # @!visibility hidden
    def to_h
      { type: COMPONENT_TYPES[:file],
        id: @id,
        spoiler: @spoiler,
        file: @file }.compact
    end
  end

  # A media gallery container lets you group files into a gallery or a grid.
  class MediaGalleryBuilder
    # Set the integer ID of this component.
    # @return [Integer, nil] integer ID of this component.
    attr_accessor :id

    # Set the items of this component.
    # @return [Array<Hash>] Media gallery items serialized as a hash.
    attr_accessor :items

    # @!visibility hidden
    def initialize(items = [], id = nil)
      @id = id
      @items = items
    end

    # Add a gallery item to this media gallery collection.
    # @param media [String] The URL of this media item.
    # @param description [String, nil] An optional description of this media item.
    # @param spoiler [true, false, nil] Whether this argument should be spoilered. Defaults to false.
    def gallery_item(media:, description: nil, spoiler: nil)
      @items << { media: { url: media }, description: description, spoiler: spoiler }.compact
    end

    alias_method :item, :gallery_item

    # @!visibility hidden
    def to_h
      { type: COMPONENT_TYPES[:media_gallery], items: @items }
    end
  end

  # A section allows you to group together text display components,
  # and optionally pair it with a button or a thumbnail. More components
  # may be supported in the future.
  class SectionBuilder
    # Set the integer ID of this component.
    # @return [Integer, nil] integer ID of this component.
    attr_accessor :id

    # @!visibility hidden
    def initialize(components = [], accessory = nil, id = nil)
      @components = components
      @accessory = accessory
      @id = id
    end

    # Add a text display component to this section.
    # @param text [String] Content of the component.
    def text_display(text:, id: nil)
      @components << { type: COMPONENT_TYPES[:text_display], content: text, id: id }.compact
    end

    # Set the accessory to a thumbnail for this media gallery collection.
    # @param media [String] The URL of the media item for this thumbnail.
    # @param description [String, nil] An optional description of this media item.
    # @param spoiler [true, false, nil] Whether this argument should be spoilered. Defaults to false.
    def thumbnail(media:, description: nil, spoiler: nil)
      @accessory = { type: COMPONENT_TYPES[:thumbnail], media: { url: media }, description: description, spoiler: spoiler }.compact
    end

    # Set the accessory to a button for this media gallery collection.
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
      style = BUTTON_STYLES[style] || style

      emoji = case emoji
              when Integer, String
                emoji.to_i.positive? ? { id: emoji } : { name: emoji }
              else
                emoji&.to_h
              end

      @accessory = { type: COMPONENT_TYPES[:button], id: id, label: label, emoji: emoji, style: style, custom_id: custom_id, disabled: disabled, url: url }.compact
    end

    # @!visibility hidden
    def to_h
      { type: COMPONENT_TYPES[:section], components: @components, accessory: @accessory }.compact
    end
  end

  # This builder can be used to construct a container. A container can hold several other types of components
  # including other action rows. A container can currently have a maximum of 10 components inside of it.
  class ContainerBuilder
    # Set the integer ID of this component.
    # @return [Integer, nil] integer ID of this component.
    attr_accessor :id

    # @return [Integer, nil] the colour of the bar to the side, in decimal form.
    attr_reader :colour
    alias_method :color, :colour

    # If this container be spoilered.
    # @return [true, false, nil] If this container is a spoiler or not.
    attr_accessor :spoiler

    # @!visibility hidden
    def initialize(id = nil, components = [], colour = nil, spoiler = nil)
      @components = components
      @spoiler = spoiler
      @id = id

      process_color(colour)
    end

    # Sets the colour of the bar to the side of the embed to something new.
    # @param value [String, Integer, {Integer, Integer, Integer}, #to_i, nil] The colour in decimal,
    # hexadecimal, R/G/B decimal, or nil if the container should have no color.
    def colour=(value)
      process_color(value)
    end

    alias_method :color=, :colour=

    # Add a text display component to this container.
    # @param id [Integer, nil] Integer ID of this component.
    # @param text [String] Set the text display of this component.
    # @yieldparam builder [TextDisplayBuilder] The text display object is yielded to allow for modification of attributes.
    def text_display(id: nil, text: nil)
      builder = TextDisplayBuilder.new(text, id)

      yield builder if block_given?

      @components << builder
    end

    # Add a section to this container.
    # @param id [Integer, nil] Integer ID of this section component.
    # @param components [Array<Components>] Optional array of text display components.
    # @param accessory [Hash, nil] Optional thumbnail or button accessory to include.
    # @yieldparam builder [SectionBuilder] The section object is yielded to allow for modification of attributes.
    def section(id: nil, components: [], accessory: nil)
      builder = SectionBuilder.new(components, accessory, id)

      yield builder if block_given?

      @components << builder
    end

    # Add a media gallery to this container.
    # @param id [Integer, nil] Integer ID of this media gallery component.
    # @param items [Array<Hash>] Array of media gallery components to include.
    # @yieldparam builder [MediaGalleryBuilder] The media gallery object is yielded to allow for modification of attributes.
    def media_gallery(id: nil, items: [])
      builder = MediaGalleryBuilder.new(items, id)

      yield builder if block_given?

      @components << builder
    end

    # Add a seperator to this container.
    # @param id [Integer, nil] Integer ID of this seperator component.
    # @param divider [true, false] Whether this seperator is a divider. Defaults to true.
    # @param spacing [Integer, nil] The amount of spacing for this seperator component.
    # @yieldparam builder [SeperatorBuilder] The seperator object is yielded to allow for modification of attributes.
    def seperator(id: nil, divider: true, spacing: nil)
      builder = SeperatorBuilder.new(divider, spacing, id)

      yield builder if block_given?

      @components << builder
    end

    # Add a file to this container.
    # @param id [Integer, nil] Integer ID of this file component.
    # @param file [String, nil] An attachment://<filename> reference.
    # @param spoiler [true, false] If this file should be spoilered. Defaults to false.
    # @yieldparam builder [FileBuilder] The file object is yielded to allow for modification of attributes.
    def file(id: nil, file: nil, spoiler: false)
      builder = FileBuilder.new(file, spoiler, id)

      yield builder if block_given?

      @components << builder
    end

    # Add an action row to this container, this allows for some interesting nesting.
    # @param id [Integer] ID of this action row.
    # @yieldparam builder [RowBuilder] The row builder object is yielded to allow for addition of components.
    def row(id: nil)
      builder = RowBuilder.new(id)

      yield builder if block_given?

      @components << builder
    end

    # @!visibility hidden
    def to_h
      { type: COMPONENT_TYPES[:container],
        accent_color: @colour,
        spoiler: @spoiler,
        components: @components.map(&:to_h) }.compact
    end

    private

    # @!visibility private
    # @note for internal use only
    # Process the color into an integer value.
    def process_color(value)
      if value.nil?
        @colour = nil
      elsif value.is_a? Integer
        raise ArgumentError, 'Embed colour must be 24-bit!' if value >= 16_777_216

        @colour = value
      elsif value.is_a? String
        self.colour = value.delete('#').to_i(16)
      elsif value.is_a? Array
        raise ArgumentError, 'Colour tuple must have three values!' if value.length != 3

        self.colour = (value[0] << 16) | (value[1] << 8) | value[2]
      else
        self.colour = value.to_i
      end
    end
  end

  # @!visibility hidden
  attr_reader :components

  def initialize
    @components = []

    yield self if block_given?
  end

  # Add a new ActionRow to the view
  # @param id [Integer] ID of this action row.
  # @yieldparam [RowBuilder]
  def row(id: nil)
    new_row = RowBuilder.new(id)

    yield new_row

    @components << new_row
  end

  # Add a text display component to this container.
  # @param id [Integer, nil] Integer ID of this component.
  # @param text [String] Set the text display of this component.
  # @yieldparam builder [TextDisplayBuilder] The text display object is yielded to allow for modification of attributes.
  def text_display(id: nil, text: nil)
    builder = TextDisplayBuilder.new(text, id)

    yield builder if block_given?

    @components << builder
  end

  # Add a section to this container.
  # @param id [Integer, nil] Integer ID of this section component.
  # @param components [Array<Components>] Optional array of text display components.
  # @param accessory [Hash, nil] Optional thumbnail or button accessory to include.
  # @yieldparam builder [SectionBuilder] The section object is yielded to allow for modification of attributes.
  def section(id: nil, components: [], accessory: nil)
    builder = SectionBuilder.new(components, accessory, id)

    yield builder if block_given?

    @components << builder
  end

  # Add a media gallery to this container.
  # @param id [Integer, nil] Integer ID of this media gallery component.
  # @param items [Array<Hash>] Array of media gallery components to include.
  # @yieldparam builder [MediaGalleryBuilder] The media gallery object is yielded to allow for modification of attributes.
  def media_gallery(id: nil, items: [])
    builder = MediaGalleryBuilder.new(items, id)

    yield builder if block_given?

    @components << builder
  end

  # Add a seperator to this container.
  # @param id [Integer, nil] Integer ID of this seperator component.
  # @param divider [true, false] Whether this seperator is a divider. Defaults to true.
  # @param spacing [Integer, nil] The amount of spacing for this seperator component.
  # @yieldparam builder [SeperatorBuilder] The seperator object is yielded to allow for modification of attributes.
  def seperator(id: nil, divider: true, spacing: nil)
    builder = SeperatorBuilder.new(divider, spacing, id)

    yield builder if block_given?

    @components << builder
  end

  # Add a file to this container.
  # @param id [Integer, nil] Integer ID of this file component.
  # @param file [String, nil] An attachment://<filename> reference.
  # @param spoiler [true, false] If this file should be spoilered. Defaults to false.
  # @yieldparam builder [FileBuilder] The file object is yielded to allow for modification of attributes.
  def file(id: nil, file: nil, spoiler: false)
    builder = FileBuilder.new(file, spoiler, id)

    yield builder if block_given?

    @components << builder
  end

  # Add a container component.
  # @param id [Integer, nil] Integer ID of this container component.
  # @param components [Array<Hash>] Container components to include.
  # @param colour [String, Integer, {Integer, Integer, Integer}, #to_i, nil] The colour in decimal,
  # hexadecimal, R/G/B decimal, or nil if the container should have no color.
  # @param spoiler [true, false] Whether this container should be spoilered. Defaults to false.
  # @yieldparam builder [ContainerBuilder] The container object is yielded to allow for modification of attributes.
  def container(id: nil, components: [], colour: nil, color: nil, spoiler: false)
    builder = ContainerBuilder.new(id, components, colour || color, spoiler)

    yield builder if block_given?

    @components << builder
  end

  # @!visibility hidden
  # @return [Array<RowBuilder>]
  def rows
    @components.select { |component| component.is_a?(RowBuilder) }
  end

  # @!visibility private
  # @return [Array<Hash>]
  def to_a
    @components.map(&:to_h)
  end
end
