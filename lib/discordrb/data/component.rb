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
      when Webhooks::View::COMPONENT_TYPES[:string_select], Webhooks::View::COMPONENT_TYPES[:user_select], Webhooks::View::COMPONENT_TYPES[:role_select], Webhooks::View::COMPONENT_TYPES[:mentionable_select], Webhooks::View::COMPONENT_TYPES[:channel_select]
        SelectMenu.new(data, bot)
      when Webhooks::Modal::COMPONENT_TYPES[:text_input]
        TextInput.new(data, bot)
      when Webhooks::View::COMPONENT_TYPES[:section]
        Section.new(data, bot)
      when Webhooks::View::COMPONENT_TYPES[:text_display]
        TextDisplay.new(data, bot)
      when Webhooks::View::COMPONENT_TYPES[:thumbnail]
        Thumbnail.new(data, bot)
      when Webhooks::View::COMPONENT_TYPES[:media_gallery]
        MediaGallery.new(data, bot)
      when Webhooks::View::COMPONENT_TYPES[:file]
        File.new(data, bot)
      when Webhooks::View::COMPONENT_TYPES[:seperator]
        Seperator.new(data, bot)
      when Webhooks::View::COMPONENT_TYPES[:container]
        Container.new(data, bot)
      when Webhooks::Modal::COMPONENT_TYPES[:label]
        Label.new(data, bot)
      when Webhooks::Modal::COMPONENT_TYPES[:file_upload]
        FileUpload.new(data, bot)
      end
    end

    # Represents a row of components
    class ActionRow
      include Enumerable

      # @return [Integer] the integer ID of this action row component.
      attr_reader :id

      # @return [Array<Button>] the components contained within this action row.
      attr_reader :components

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
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

      # Get all buttons in this row
      # @return [Array<Button>]
      def text_inputs
        select { |component| component.is_a? TextInput }
      end

      # @!visibility private
      def to_a
        @components
      end
    end

    # An interactable button component.
    class Button
      # @return [Integer] the ID of this button component.
      attr_reader :id

      # @return [String] the label of this button component.
      attr_reader :label

      # @return [Integer] the style of this button component.
      # @see Webhooks::View::BUTTON_STYLES
      attr_reader :style

      # @return [String] the custom ID of this button component.
      attr_reader :custom_id

      # @return [true, false] whether this button component is disabled.
      attr_reader :disabled

      # @return [String, nil] the URL of this button component, if the
      #   button's style is {#link?}.
      attr_reader :url

      # @return [Emoji, nil] the custom emoji of this button component.
      attr_reader :emoji

      # @!visibility private
      def initialize(data, bot)
        @bot = bot

        @id = data['id']
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
        # @return [String] the user-facing label of this option.
        attr_reader :label

        # @return [String] the value of this option.
        attr_reader :value

        # @return [String, nil] the description of this option.
        attr_reader :description

        # @return [Emoji, nil] the emoji of this option, or `nil` for no emoji.
        attr_reader :emoji

        # @!visibility hidden
        def initialize(data)
          @label = data['label']
          @value = data['value']
          @description = data['description']
          @emoji = Emoji.new(data['emoji'], @bot) if data['emoji']
        end
      end

      # @return [Integer] the ID of this select menu component.
      attr_reader :id

      # @return [Array<String>] the selected values in the modal.
      attr_reader :values

      # @return [String] the custom ID of this select menu component.
      attr_reader :custom_id

      # @return [Integer, nil] the minimum amount of options that can be chosen for this select menu component.
      attr_reader :max_values

      # @return [Integer, nil] the minimum amount of options that must be chosen for this select menu component.
      attr_reader :min_values

      # @return [String, nil] the placeholder text shown on this select menu when no options have been selected.
      attr_reader :placeholder

      # @return [Array<Option>] the options that were selected for this select menu component.
      attr_reader :options

      # @!visibility private
      def initialize(data, bot)
        @bot = bot

        @id = data['id']
        @max_values = data['max_values']
        @min_values = data['min_values']
        @placeholder = data['placeholder']
        @custom_id = data['custom_id']
        @emoji = Emoji.new(data['emoji'], @bot) if data['emoji']
        @options = data['options']&.map { |opt| Option.new(opt) } || []
        @values = data['values'] || @options&.map(&:value)
      end
    end

    # Text input component for use in modals. Can be either a line (`short`), or a multi line (`paragraph`) block.
    class TextInput
      # Single line text input
      SHORT = 1
      # Multi-line text input
      PARAGRAPH = 2

      # @return [Integer] the ID of this text input componet.
      attr_reader :id

      # @return [String] the custom ID of this text input component.
      attr_reader :custom_id

      # @return [Symbol] the style of this component. Will either be (`:short`) or (`:paragraph`).
      attr_reader :style

      # @return [String] the label shown above this text input component.
      attr_reader :label

      # @return [Integer, nil] the minimum amount of characters that must be typed into this text input component.
      attr_reader :min_length

      # @return [Integer, nil] the maximum amount of characters that must be typed into this text input component.
      attr_reader :max_length

      # @return [true, false] whether something must be typed into this text input component.
      attr_reader :required
      alias_method :required?, :required

      # @return [String, nil] the value the user typed into this text input component.
      attr_reader :value

      # @return [String, nil] the placeholder text shown on this text input component.
      attr_reader :placeholder

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @style = data['style'] == SHORT ? :short : :paragraph
        @label = data['label']
        @min_length = data['min_length']
        @max_length = data['max_length']
        @required = data['required']
        @value = data['value']
        @placeholder = data['placeholder']
        @custom_id = data['custom_id']
      end

      # @return [true, false] whether the text input's style is (`:short`).
      def short?
        @style == :short
      end

      # @return [true, false] whether the text input's style is (`:paragraph`).
      def paragraph?
        @style == :paragraph
      end
    end

    # Sections allow you to group text display components with an accessory.
    class Section
      # @return [Integer] the ID of this section.
      attr_reader :id

      # @return [Button, Thumbnail] the accessory of this section.
      attr_reader :accessory

      # @return [Array<TextDisplay>] array of components in this section.
      attr_reader :components

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @accessory = Components.from_data(data['accessory'], bot)
        @components = data['components'].map { |component| Components.from_data(component, bot) }
      end

      # @return [Button, nil] the button attached to this section.
      def button
        @accessory if @accessory.is_a?(Button)
      end

      # @return [Thumbnail, nil] the thumbnail attached to this section.
      def thumbnail
        @accessory if @accessory.is_a?(Thumbnail)
      end
    end

    # Unfurled media objects allow you to specify an arbitrary url or attachment://<filename> reference.
    class UnfurledMedia
      # @return [String] the URL this attachment can be downloaded at.
      attr_reader :url

      # @return [String] the attachment's proxied URL.
      attr_reader :proxy_url

      # @return [Integer, nil] the width of an image file, in pixels, or `nil` if the file is not an image.
      attr_reader :width

      # @return [Integer, nil] the height of an image file, in pixels, or `nil` if the file is not an image.
      attr_reader :height

      # @return [String] the media's content type.
      attr_reader :content_type

      # @return [Integer, nil] the ID of the uploaded attachment. Only present if the media item was uploaded as an attachment.
      attr_reader :attachment_id

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @url = data['url']
        @proxy_url = data['proxy_url']
        @width = data['width']
        @height = data['height']
        @content_type = data['content_type']
        @attachment_id = data['attachment_id']&.to_i
      end
    end

    # Seperators allow you to divide other components with a barrier.
    class Seperator
      # @return [Integer] the ID of this seperator.
      attr_reader :id

      # @return [true, false] if this seperator is a divider or not.
      attr_reader :divider
      alias_method :divider?, :divider

      # @return [Integer] if this seperator has `small` (1) or `large` (2) spacing.
      attr_reader :spacing

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @divider = data['divider']
        @spacing = data['spacing']
      end

      # @return [true, false] whether the spacing is small.
      def small?
        @spacing == 1
      end

      # @return [true, false] whether the spacing is large.
      def large?
        @spacing == 2
      end
    end

    # A media gallery is a collection of images, videos, or GIFs that can be grouped into a gallery grid.
    class MediaGallery
      # A media Gallery item.
      class Item
        # @return [UnfurledMedia] the media of this gallery item.
        attr_reader :media

        # @return [String, nil] the alternative text of this item.
        attr_reader :description
        alias_method :alt_text, :description

        # @return [true, false] If this gallery item is spoilered.
        attr_reader :spoiler
        alias_method :spoiler?, :spoiler

        # @!visibility private
        def initialize(data, bot)
          @bot = bot
          @media = UnfurledMedia.new(data['media'], bot)
          @description = data['description']
          @spoiler = data['spoiler']
        end
      end

      # @return [Integer] the ID of this gallery.
      attr_reader :id

      # @return [Array<Item>] array of media gallery items.
      attr_reader :items

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @items = data['items'].map { |item| Item.new(item, bot) }
      end
    end

    # Thumbnails are containers for media. They can have alt text, and be spoilered.
    class Thumbnail
      # @return [Integer] the ID of this thumbnail.
      attr_reader :id

      # @return [UnfurledMedia] media item of this thumbnail.
      attr_reader :media

      # @return [String, nil] the alternative text of this thumbnail.
      attr_reader :description
      alias_method :alt_text, :description

      # @return [true, false] if this thumbnail is spoilered or not.
      attr_reader :spoiler
      alias_method :spoiler?, :spoiler

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @media = UnfurledMedia.new(data['media'], bot)
        @description = data['description']
        @spoiler = data['spoiler']
      end
    end

    # Containers allow you to group together other components. You can add an accent color and spoiler them.
    class Container
      # @return [Integer] the ID of this container.
      attr_reader :id

      # @return [ColourRGB, nil] the accent color of this thumbnail, or nil if there isn't one.
      attr_reader :colour
      alias_method :color, :colour

      # @return [true, false] if this container is spoilered or not.
      attr_reader :spoiler
      alias_method :spoiler?, :spoiler

      # @return [Array<Component>] the components included within this container.
      attr_reader :components

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @spoiler = data['spoiler']
        @colour = data['accent_color'] ? ColourRGB.new(data['accent_color']) : nil
        @components = data['components'].filter_map { |component| Components.from_data(component, bot) }
      end

      # Get the buttons contained in this container.
      # @return [Array<Button>] the buttons contained within this container.
      def buttons
        components = @components.flat_map do |component|
          case component
          when Components::ActionRow
            component.buttons
          when Component::Section
            component.button
          when Component::Button
            component
          end
        end

        components.compact
      end
    end

    # File components allow you to send a file. You can spoiler these files as well.
    class File
      # @return [Integer] the ID of this file.
      attr_reader :id

      # @return [UnfurledMedia] the attached file.
      attr_reader :file

      # @return [String] the name of the attached file.
      attr_reader :name

      # @return [Integer] the size of the attached file in bytes.
      attr_reader :size

      # @return [true, false] if this file is spoilered or not.
      attr_reader :spoiler
      alias_method :spoiler?, :spoiler

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @file = UnfurledMedia.new(data['file'], bot)
        @name = data['name']
        @size = data['size']
        @spoiler = data['spoiler']
      end
    end

    # Text displays are a lightweight container for text.
    class TextDisplay
      # @return [Integer] the ID of this text display.
      attr_reader :id

      # @return [String] the content within this text display.
      attr_reader :content
      alias_method :text, :content
      alias_method :to_s, :content

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @content = data['content']
      end
    end

    # Label components are containers for other components within a modal.
    class Label
      # @return [Integer] the ID of this label component.
      attr_reader :id

      # @return [Component] the interactive component for this label component.
      attr_reader :component

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @component = Components.from_data(data['component'], bot)
      end
    end

    # A surface that a user can use to upload files in a modal.
    class FileUpload
      # @return [Integer] the ID of this file upload component.
      attr_reader :id

      # @return [Array<String>] the IDs of the uploaded attachments.
      attr_reader :values

      # @return [String] the custom ID of this file upload component.
      attr_reader :custom_id

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @values = data['values']
        @custom_id = data['custom_id']
      end
    end
  end
end
