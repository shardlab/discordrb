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
      # @return [Integer] the ID of the button.
      attr_reader :id

      # @return [String] the label of the button.
      attr_reader :label

      # @return [Integer] the style of the button.
      attr_reader :style

      # @return [String] the custom ID of the button.
      attr_reader :custom_id

      # @return [true, false] whether or not the button is disabled.
      attr_reader :disabled

      # @return [String, nil] the URL of the button if applicable.
      attr_reader :url

      # @return [Emoji, nil] the custom emoji of the button component.
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
        @bot.add_await(key, Discordrb::Events::ButtonEvent, { custom_id: @custom_id }.merge!(attributes), &block)
      end

      # Await a button click, blocking.
      def await_click!(**attributes, &block)
        @bot.add_await!(Discordrb::Events::ButtonEvent, { custom_id: @custom_id }.merge!(attributes), &block)
      end
    end

    # An interactable select menu component.
    class SelectMenu
      # A select menu option.
      class Option
        # @return [String] the of the option.
        attr_reader :label

        # @return [String] the value of the option.
        attr_reader :value

        # @return [String, nil] the description of the option.
        attr_reader :description

        # @return [Emoji, nil] the emoji of the option, or `nil`.
        attr_reader :emoji

        # @!visibility hidden
        def initialize(data)
          @label = data['label']
          @value = data['value']
          @description = data['description']
          @emoji = Emoji.new(data['emoji'], @bot) if data['emoji']
        end
      end

      # @return [Integer] the ID of the select menu.
      attr_reader :id

      # @return [Array<String>] the selected values.
      attr_reader :values

      # @return [String] the custom ID of the select menu.
      attr_reader :custom_id

      # @return [Integer, nil] the minimum amount of values that be selected.
      attr_reader :max_values

      # @return [Integer, nil] the maximum amount of values that can be selected.
      attr_reader :min_values

      # @return [String, nil] the default placeholder text shown on the select menu.
      attr_reader :placeholder

      # @return [Array<Option>] the options in the select menu, or the selected options.
      attr_reader :options

      # @!visibility private
      def initialize(data, bot)
        @bot = bot

        @id = data['id']
        @max_values = data['max_values']
        @min_values = data['min_values']
        @placeholder = data['placeholder']
        @custom_id = data['custom_id']
        @options = data['options']&.map { |option| Option.new(option) } || []
        @values = data['values'] || @options&.map(&:value)
      end
    end

    # A component that can accept user-input in a modal.
    class TextInput
      # Single line text input
      SHORT = 1
      # Multi-line text input
      PARAGRAPH = 2

      # @return [Integer] the ID of the text input.
      attr_reader :id

      # @return [Symbol] the style of the text input.
      attr_reader :style

      # @return [String] the custom ID of the text input.
      attr_reader :custom_id

      # @return [String] the label shown above the text input.
      attr_reader :label

      # @return [Integer, nil] the maximum amount of text that can be typed.
      attr_reader :max_length

      # @return [Integer, nil] the minimum amount of text that must be typed.
      attr_reader :min_length

      # @return [true, false] whether a value must be typed into the text input.
      attr_reader :required
      alias_method :required?, :required

      # @return [String, nil] the value the user typed into the text input component.
      attr_reader :value

      # @return [String, nil] the placeholder text shown on the text input component.
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

    # A grouping of text displays with an accessory.
    class Section
      # @return [Integer] the ID of the section.
      attr_reader :id

      # @return [Button, Thumbnail] the accessory of the section.
      attr_reader :accessory

      # @return [Array<TextDisplay>] the components in the section.
      attr_reader :components

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @accessory = Components.from_data(data['accessory'], bot)
        @components = data['components'].map { |component| Components.from_data(component, bot) }
      end

      # Check if the accessory is a button.
      # @return [Button, nil] the button attached to the section.
      def button
        @accessory if @accessory.is_a?(Button)
      end

      # Check if the accessory is a thumbnail.
      # @return [Thumbnail, nil] the thumbnail attached to the section.
      def thumbnail
        @accessory if @accessory.is_a?(Thumbnail)
      end
    end

    # Metadata about a piece of media.
    class UnfurledMedia
      # @return [String] the CDN URL of the media.
      attr_reader :url

      # @return [Integer, nil] the width of the media, if it's an image.
      attr_reader :width

      # @return [Integer, nil] the height of the media, if it's an image.
      attr_reader :height

      # @return [String, nil] the CDN URL of the media, if it's an image.
      attr_reader :proxy_url

      # @return [String] the media's mime content type such as `image/png`.
      attr_reader :content_type

      # @return [Integer, nil] the ID of the uploaded attachment, if applicable.
      attr_reader :attachment_id

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @url = data['url']
        @width = data['width']
        @height = data['height']
        @proxy_url = data['proxy_url']
        @content_type = data['content_type']
        @attachment_id = data['attachment_id']&.to_i
      end
    end

    # A barrier component.
    class Seperator
      # @return [Integer] the ID of this seperator.
      attr_reader :id

      # @return [Integer] the size of the seperator's spacing.
      attr_reader :spacing

      # @return [true, false] whether or not the seperator is a divider.
      attr_reader :divider
      alias_method :divider?, :divider

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @spacing = data['spacing']
        @divider = data['divider']
      end

      # Check if the spacing of the seperator is small.
      # @return [true, false] whether the spacing is small.
      def small?
        @spacing == 1
      end

      # Check if the spacing of the seperator is large.
      # @return [true, false] whether the spacing is large.
      def large?
        @spacing == 2
      end
    end

    # A Collection of media grouped into a gallery-grid.
    class MediaGallery
      # A media Gallery item.
      class Item
        # @return [UnfurledMedia] the media of the item.
        attr_reader :media

        # @return [String, nil] the description of the item.
        attr_reader :description

        # @return [true, false] whether or not the media is spoilered.
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

      # @return [Integer] the ID of the gallery.
      attr_reader :id

      # @return [Array<Item>] the media in the gallery.
      attr_reader :items

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @items = data['items'].map { |item| Item.new(item, bot) }
      end
    end

    # A thumbnail accessory component.
    class Thumbnail
      # @return [Integer] the ID of the thumbnail.
      attr_reader :id

      # @return [UnfurledMedia] the media of the thumbnail.
      attr_reader :media

      # @return [String, nil] the description of the thumbnail.
      attr_reader :description

      # @return [true, false] whether or not the thumbnail is spoilered.
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

    # A grouping of components with an accent colour, similar to an embed.
    class Container
      # @return [Integer] the ID of the container.
      attr_reader :id

      # @return [ColourRGB, nil] the accent color of the container.
      attr_reader :colour
      alias_method :color, :colour

      # @return [true, false] whether or not the container is spoilered.
      attr_reader :spoiler
      alias_method :spoiler?, :spoiler

      # @return [Array<Component>] the components contained within the container.
      attr_reader :components

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @spoiler = data['spoiler']
        @colour = data['accent_color'] ? ColourRGB.new(data['accent_color']) : nil
        @components = data['components'].filter_map { |component| Components.from_data(component, bot) }
      end

      # Get the buttons contained in the container.
      # @return [Array<Button>] the buttons contained within the container.
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

    # A file component.
    class File
      # @return [Integer] the ID of the file.
      attr_reader :id

      # @return [UnfurledMedia] the attached file.
      attr_reader :file

      # @return [String] the name of the attached file.
      attr_reader :name

      # @return [Integer] the size of the file in bytes.
      attr_reader :size

      # @return [true, false] whether or not the file is spoilered.
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

    # A lightweight way to display text content.
    class TextDisplay
      # @return [Integer] the ID of the text display.
      attr_reader :id

      # @return [String] the content in the text display.
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

    # A parent component for other modal components.
    class Label
      # @return [Integer] the ID of the label component.
      attr_reader :id

      # @return [Component] the interactive component in the label.
      attr_reader :component

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @component = Components.from_data(data['component'], bot)
      end
    end

    # A surface that can be used to upload files in a modal.
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
