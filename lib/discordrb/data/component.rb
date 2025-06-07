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
      when Webhooks::View::COMPONENT_TYPES[:string_select]
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
      end
    end

    # Represents a row of components
    class ActionRow
      include Enumerable

      # @return [Integer]
      attr_reader :id

      # @return [Array<Button>]
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
      # @return [Integer]
      attr_reader :id

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

      # @return [Integer]
      attr_reader :id

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

        @id = data['id']
        @max_values = data['max_values']
        @min_values = data['min_values']
        @placeholder = data['placeholder']
        @custom_id = data['custom_id']
        @emoji = Emoji.new(data['emoji'], @bot) if data['emoji']
        @options = data['options'].map { |opt| Option.new(opt) }
      end
    end

    # Text input component for use in modals. Can be either a line (`short`), or a multi line (`paragraph`) block.
    class TextInput
      # Single line text input
      SHORT = 1
      # Multi-line text input
      PARAGRAPH = 2

      # @return [Integer]
      attr_reader :id

      # @return [String]
      attr_reader :custom_id

      # @return [Symbol]
      attr_reader :style

      # @return [String]
      attr_reader :label

      # @return [Integer, nil]
      attr_reader :min_length

      # @return [Integer, nil]
      attr_reader :max_length

      # @return [true, false]
      attr_reader :required

      # @return [String, nil]
      attr_reader :value

      # @return [String, nil]
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

      def short?
        @style == :short
      end

      def paragraph?
        @style == :paragraph
      end

      def required?
        @required
      end
    end

    # Sections allow you to group text display components with an accessory.
    class Section
      # @return [Integer] ID of this section.
      attr_reader :id

      # @return [Button, Thumbnail] The accessory of this section.
      attr_reader :accessory

      # @return [Array<TextDisplay>] Array of components in this section.
      attr_reader :components

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @accessory = Components.from_data(data['accessory'], bot)
        @components = data['components'].map { |component| Components.from_data(component, bot) }
      end

      # @return [Boolean] If the accessory is a button or not.
      def button?
        @accessory.is_a?(Button)
      end

      # @return [Boolean] If the accessory is a thumbnail or not.
      def thumbnail?
        @accessory.is_a?(Thumbnail)
      end
    end

    # Unfurled media objects allow you to specify an arbitrary url or attachment://<filename> reference.
    class UnfurledMedia
      # @return [String] The URL this attachment can be downloaded at.
      attr_reader :url

      # @return [String, nil] The attachment's proxied URL.
      attr_reader :proxy_url

      # @return [Integer, nil] The width of an image file, in pixels, or `nil` if the file is not an image.
      attr_reader :width

      # @return [Integer, nil] The height of an image file, in pixels, or `nil` if the file is not an image.
      attr_reader :height

      # @return [String, nil] The media's content type.
      attr_reader :content_type

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @url = data['url']
        @proxy_url = data['proxy_url']
        @width = data['width']
        @height = data['height']
        @content_type = data['content_type']
      end
    end

    # Seperators allow you to divide other components with a barrier.
    class Seperator
      # @return [Integer] ID of this seperator.
      attr_reader :id

      # @return [true, false] If this seperator is a divider or not.
      attr_reader :divider
      alias_method :divider?, :divider

      # @return [Integer] If this seperator has `small` (1) or `large` (2) spacing.
      attr_reader :spacing

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @divider = data['divider']
        @spacing = data['spacing']
      end

      # @return [true, false] If the spacing is small.
      def small?
        @spacing == 1
      end

      # @return [true, false] If the spacing is large.
      def large?
        @spacing == 2
      end
    end

    # A media gallery is a collection of images, videos, or GIFs that can be grouped into a gallery grid.
    class MediaGallery
      # A media Gallery item.
      class Item
        # @return [UnfurledMedia] Media of this gallery item.
        attr_reader :media

        # @return [String, nil] Alt text/description of this item.
        attr_reader :description

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

      # @return [Integer] ID of this gallery.
      attr_reader :id

      # @return [Array<Item>] Array of media gallery items.
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
      # @return [Integer] ID of this thumbnail.
      attr_reader :id

      # @return [UnfurledMedia] Media item of this thumbnail.
      attr_reader :media

      # @return [String, nil] Alt text/description of this thumbnail.
      attr_reader :description

      # @return [true, false] If this thumbnail is spoilered or not.
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
      # @return [Integer] ID of this container.
      attr_reader :id

      # @return [ColourRGB, nil] The accent color of this thumbnail, or nil if there isn't one.
      attr_reader :colour
      alias_method :color, :colour

      # @return [true, false] If this container is spoilered or not.
      attr_reader :spoiler
      alias_method :spoiler?, :spoiler

      # @return [Array<Component>] Components included within this container.
      attr_reader :components

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @spoiler = data['spoiler']
        @colour = data['accent_color'] ? ColourRGB.new(data['accent_color']) : nil
        @components = data['components'].map { |component| Components.from_data(component, bot) }
      end
    end

    # File components allow you to send a file. You can spoiler these files as well.
    class File
      # @return [Integer] ID of this file.
      attr_reader :id

      # @return [UnfurledMedia] The attached file.
      attr_reader :file

      # @return [true, false] If this file is spoilered or not.
      attr_reader :spoiler
      alias_method :spoiler?, :spoiler

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @file = UnfurledMedia.new(data['file'], bot)
        @spoiler = data['spoiler']
      end
    end

    # Text displays are a lightweight container for text.
    class TextDisplay
      # @return [Integer] ID of this text display.
      attr_reader :id

      # @return [String] The content within this text display.
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
  end
end
