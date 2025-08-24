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

  # A text display component allows you to send text.
  class TextDisplayBuilder
    # Set the 32-bit integer ID of this component.
    # @return [Integer, nil] the integer ID of this text display.
    attr_accessor :id

    # Set the content of this component.
    # @return [String] the content of this text display.
    attr_accessor :text

    # @!visibility private
    def initialize(id = nil, text = nil)
      @id = id
      @text = text
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:text_display], content: @text, id: @id }.compact
    end
  end

  # A seperator allows you to add seperation between components.
  class SeperatorBuilder
    # Set the 32-bit integer ID of this seperator.
    # @return [Integer, nil] the integer ID of this seperator.
    attr_accessor :id

    # Set whether this seperator is a divider.
    # @return [true, false] if this seperator is a divider.
    attr_accessor :divider

    # Set the spacing size of this seperator.
    # @return [Symbol, Integer] the spacing of the seperator. See {SEPERATOR_SIZES}.
    attr_accessor :spacing

    # @!visibility private
    def initialize(id = nil, divider = nil, spacing = nil)
      @id = id
      @spacing = spacing
      @divider = divider
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:seperator], id: @id, spacing: SEPERATOR_SIZES[spacing] || spacing, divider: @divider }.compact
    end
  end

  # A file component lets you send a file via an attachment://<filename> reference.
  class FileBuilder
    # Set the 32-bit integer ID of this file.
    # @return [Integer, nil] the integer ID of this file.
    attr_accessor :id

    # Set the attachment://<filename> reference of this file.
    # @return [String, nil] the attachment://<filename> reference.
    attr_accessor :url

    # Set whether this file should be spoilered.
    # @return [true, false] whether or not this file is spoilered.
    attr_accessor :spoiler

    # @!visibility private
    def initialize(id = nil, url = nil, spoiler = false)
      @id = id
      @url = url
      @spoiler = spoiler
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:file], id: @id, spoiler: @spoiler, file: { url: @url } }.compact
    end
  end

  # A media gallery component lets you group together images, videos, or GIFs into a gallery grid.
  class MediaGalleryBuilder
    # Set the 32-bit integer ID of this media gallery.
    # @return [Integer, nil] the integer ID of this media gallery.
    attr_accessor :id

    # Set the media gallery items of this media gallery.
    # @return [Array<#to_h>] the items in the media gallery.
    attr_accessor :items

    # @!visibility private
    def initialize(id = nil, items = [])
      @id = id
      @items = items
    end

    # Add a gallery item to the media gallery.
    # @param url [String] The URL of this media item.
    # @param description [String, nil] A description of this media item.
    # @param spoiler [true, false] Whether the gallery item should be spoilered.
    def gallery_item(url:, description: nil, spoiler: false)
      @items << { media: { url: url }, description: description, spoiler: spoiler }.compact
    end

    alias_method :item, :gallery_item

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:media_gallery], items: @items.map(&:to_h) }
    end
  end

  # A section allows you to group together text display components, and pair them with an accessory.
  class SectionBuilder
    # Set the 32-bit integer ID of this section.
    # @return [Integer, nil] the integer ID of this section.
    attr_accessor :id

    # @!visibility private
    def initialize(id = nil, accessory = nil, components = [])
      @id = id
      @accessory = accessory
      @components = components
    end

    # Add a text display component to the section.
    # @param id [Integer, nil] Integer ID of this component.
    # @param text [String] Set the text display of this component.
    # @yieldparam builder [TextDisplayBuilder] The text display builder is yielded to allow for modification of attributes.
    def text_display(id: nil, text: nil)
      builder = TextDisplayBuilder.new(id, text)

      yield builder if block_given?

      @components << builder
    end

    # Set the thumbnail for this section.
    # @param url [String] The URL to the thumbnail's media item.
    # @param description [String, nil] A description for the thumbnail's media item.
    # @param spoiler [true, false] Whether the thumbanail should be spoilered.
    # @param id [Integer, nil] The 32-bit integer ID of this component.
    def thumbnail(url:, description: nil, spoiler: false, id: nil)
      @accessory = { type: COMPONENT_TYPES[:thumbnail], media: { url: url }, description: description, spoiler: spoiler, id: id }.compact
    end

    # Set the button for this section.
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

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:section], components: @components.map(&:to_h), accessory: @accessory.to_h }.compact
    end
  end

  # This builder can be used to construct a container. A container can hold several other types of components
  # including other action rows. A container can currently have a maximum of 10 components inside of it.
  class ContainerBuilder
    # Set the 32-bit integer ID of this container.
    # @return [Integer, nil] the integer ID of this container.
    attr_accessor :id

    # Set the accent colour of this container.
    # @return [Integer, nil] the colour of the container's sidebar.
    attr_accessor :colour
    alias_method :color, :colour
    alias_method :color=, :colour=

    # Set whether this container should be spoilered.
    # @return [true, false] if this container is a spoiler or not.
    attr_accessor :spoiler

    # @!visibility private
    def initialize(id = nil, colour = nil, spoiler = nil, components = [])
      @id = id
      @colour = colour
      @spoiler = spoiler
      @components = components
    end

    # Add a text display component to this container.
    # @param id [Integer, nil] The 32-bit integer ID of this component.
    # @param text [String] Set the text display of this component.
    # @yieldparam builder [TextDisplayBuilder] The text display object is yielded to allow for modification of attributes.
    def text_display(id: nil, text: nil)
      builder = TextDisplayBuilder.new(id, text)

      yield builder if block_given?

      @components << builder
    end

    # Add a section to this container.
    # @param id [Integer, nil] The 32-bit integer ID of this section component.
    # @param accessory [#to_h, nil] An optional thumbnail or button accessory to include.
    # @param components [Array<#to_h>] An optional array of components to include.
    # @yieldparam builder [SectionBuilder] The section object is yielded to allow for modification of attributes.
    def section(id: nil, accessory: nil, components: [])
      builder = SectionBuilder.new(id, accessory, components)

      yield builder if block_given?

      @components << builder
    end

    # Add a media gallery to this container.
    # @param id [Integer, nil] The 32-bit integer ID of this media gallery component.
    # @param items [Array<Hash>] Array of media gallery components to include.
    # @yieldparam builder [MediaGalleryBuilder] The media gallery object is yielded to allow for modification of attributes.
    def media_gallery(id: nil, items: [])
      builder = MediaGalleryBuilder.new(id, items)

      yield builder if block_given?

      @components << builder
    end

    # Add a seperator to this container.
    # @param id [Integer, nil] The 32-bit integer ID of this seperator component.
    # @param divider [true, false] Whether this seperator is a divider. Defaults to true.
    # @param spacing [Integer, nil] The amount of spacing for this seperator component.
    # @yieldparam builder [SectionBuilder] The section builder is yielded to allow for modification of attributes.
    def seperator(id: nil, divider: true, spacing: nil)
      builder = SeperatorBuilder.new(id, divider, spacing)

      yield builder if block_given?

      @components << builder
    end

    # Add a file to this container.
    # @param id [Integer, nil] The 32-bit integer ID of this file component.
    # @param url [String, nil] An attachment://<filename> reference.
    # @param spoiler [true, false] If this file should be spoilered. Defaults to false.
    # @yieldparam builder [FileBuilder] The file object is yielded to allow for modification of attributes.
    def file(id: nil, url: nil, spoiler: false)
      builder = FileBuilder.new(id, url, spoiler)

      yield builder if block_given?

      @components << builder
    end

    # Add an action row component to this container.
    # @param id [Integer, nil] The 32-bit integer ID of this action row component.
    # @yieldparam builder [RowBuilder] the action row builder is yielded to allow for the addition of components.
    def row(id: nil)
      builder = RowBuilder.new(id)

      yield builder if block_given?

      @components << builder
    end

    # @!visibility private
    def to_h
      { type: COMPONENT_TYPES[:container],
        accent_color: process_colour(@colour),
        spoiler: @spoiler,
        components: @components.map(&:to_h) }.compact
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

  # Add an action row component to the view.
  # @param id [Integer, nil] The 32-bit integer ID of this action row component.
  # @yieldparam builder [RowBuilder] the action row builder is yielded to allow for the addition of components.
  def row(id: nil)
    builder = RowBuilder.new(id)

    yield builder

    @components << builder
  end

  # Add a text display component to the view.
  # @param id [Integer, nil] The 32-bit integer ID of this component.
  # @param text [String] Set the text display of this component.
  # @yieldparam builder [TextDisplayBuilder] The text display builder is yielded to allow for modification of attributes.
  def text_display(id: nil, text: nil)
    builder = TextDisplayBuilder.new(id, text)

    yield builder if block_given?

    @components << builder
  end

  # Add a section component to the view.
  # @param id [Integer, nil] The 32-bit integer ID of this section component.
  # @param accessory [#to_h, nil] An optional thumbnail or button accessory to include.
  # @param components [Array<#to_h>] An optional array of components to include.
  # @yieldparam builder [SectionBuilder] The section builder is yielded to allow for modification of attributes.
  def section(id: nil, accessory: nil, components: [])
    builder = SectionBuilder.new(id, accessory, components)

    yield builder if block_given?

    @components << builder
  end

  # Add a media gallery to the view.
  # @param id [Integer, nil] The 32-bit integer ID of this media gallery component.
  # @param items [Array<Hash>] Array of media gallery components to include.
  # @yieldparam builder [MediaGalleryBuilder] The media gallery builder is yielded to allow for modification of attributes.
  def media_gallery(id: nil, items: [])
    builder = MediaGalleryBuilder.new(id, items)

    yield builder if block_given?

    @components << builder
  end

  # Add a seperator to the view.
  # @param id [Integer, nil] The 32-bit integer ID of this seperator component.
  # @param divider [true, false] Whether this seperator is a divider. Defaults to true.
  # @param spacing [Integer, nil] The amount of spacing for this seperator component.
  # @yieldparam builder [SeperatorBuilder] The seperator builder is yielded to allow for modification of attributes.
  def seperator(id: nil, divider: true, spacing: nil)
    builder = SeperatorBuilder.new(id, divider, spacing)

    yield builder if block_given?

    @components << builder
  end

  # Add a file to the view.
  # @param id [Integer, nil] The 32-bit integer ID of this file component.
  # @param url [String, nil] An attachment://<filename> reference.
  # @param spoiler [true, false] If this file should be spoilered. Defaults to false.
  # @yieldparam builder [FileBuilder] The file builder is yielded to allow for modification of attributes.
  def file(id: nil, url: nil, spoiler: false)
    builder = FileBuilder.new(id, url, spoiler)

    yield builder if block_given?

    @components << builder
  end

  # Add a container to the view.
  # @param id [Integer, nil] The 32-bit integer ID of this container component.
  # @param colour [String, Integer, {Integer, Integer, Integer}, #to_i, nil] The colour in decimal,
  #   hexadecimal, R/G/B decimal, or nil if the container should have no color.
  # @param spoiler [true, false] Whether this container should be spoilered. Defaults to false.
  # @param components [Array<#to_h>] The components the container should include.
  # @yieldparam builder [ContainerBuilder] The container builder is yielded to allow for modification of attributes.
  def container(id: nil, colour: nil, color: nil, spoiler: false, components: [])
    builder = ContainerBuilder.new(id, colour || color, spoiler, components)

    yield builder if block_given?

    @components << builder
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
