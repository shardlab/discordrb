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
      when Webhooks::View::COMPONENT_TYPES[:separator]
        Separator.new(data, bot)
      when Webhooks::View::COMPONENT_TYPES[:container]
        Container.new(data, bot)
      when Webhooks::Modal::COMPONENT_TYPES[:label]
        Label.new(data, bot)
      when Webhooks::Modal::COMPONENT_TYPES[:file_upload]
        FileUpload.new(data, bot)
      when Webhooks::Modal::COMPONENT_TYPES[:radio_group]
        RadioGroup.new(data, bot)
      when Webhooks::Modal::COMPONENT_TYPES[:checkbox_group]
        CheckboxGroup.new(data, bot)
      when Webhooks::Modal::COMPONENT_TYPES[:checkbox]
        Checkbox.new(data, bot)
      end
    end

    # Represents a row of components.
    class ActionRow
      include Enumerable

      # @return [Integer] the numeric identifier of the action row.
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
      # @return [Array, Enumerator]
      def each(&block)
        @components.each(&block)
      end

      # Get all the buttons in this action row.
      # @return [Array<Button>] All of the buttons in this action row.
      def buttons
        select { |component| component.is_a?(Button) }
      end

      # Get all the text inputs in this action row.
      # @return [Array<TextInput>] All of the text inputs in this action row.
      def text_inputs
        select { |component| component.is_a?(TextInput) }
      end

      # @!visibility private
      def to_a
        @components
      end
    end

    # An interactable button component.
    class Button
      # @return [Integer] the numeric identifier of the button.
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

      # @!method primary?
      #   @return [true, false] whether the button is a primary option in the group.
      # @!method secondary?
      #   @return [true, false] whether the button denotes a secondary option in the group.
      # @!method success?
      #   @return [true, false] whether the button denotes a success action in the group.
      # @!method danger?
      #   @return [true, false] whether the button denotes a dangerous action in the group.
      # @!method link?
      #   @return [true, false] whether the button is a container for a URL that will open upon click.
      Webhooks::View::BUTTON_STYLES.each do |name, value|
        define_method("#{name}?") do
          @style == value
        end
      end

      # Await a button click.
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
        # @return [String] the label of the option.
        attr_reader :label

        # @return [String] the value of the option.
        attr_reader :value

        # @return [String, nil] the description of the option.
        attr_reader :description

        # @return [Emoji, nil] the emoji of the option, or `nil`.
        attr_reader :emoji

        # @!visibility private
        def initialize(data)
          @label = data['label']
          @value = data['value']
          @description = data['description']
          @emoji = Emoji.new(data['emoji'], @bot) if data['emoji']
        end
      end

      # @return [Integer] the numeric identifier of the select menu.
      attr_reader :id

      # @return [Array<String>] the submitted values from the modal.
      attr_reader :values

      # @return [String] the custom ID used to identify the select menu.
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
        @values = data['values'] || []
        @custom_id = data['custom_id']
        @max_values = data['max_values']
        @min_values = data['min_values']
        @placeholder = data['placeholder']
        @options = data['options']&.map { |option| Option.new(option) } || []
      end
    end

    # A free-form text input bar in a modal.
    class TextInput
      # @!visibility private
      PLACEHOLDERS = %i[
        label
        min_length
        max_length
        required
        required?
        placeholder
      ].freeze

      # @!visibility private
      SHORT = 1

      # @!visibility private
      PARAGRAPH = 2

      # @return [Integer] the numeric identifier of the text input.
      attr_reader :id

      # @return [Symbol] This is deprecated and not accurate. This will
      #   be removed in the next major version (4.0.0).
      attr_reader :style

      # @return [String, nil] the value the user typed into the text input.
      attr_reader :value

      # @return [String] the developer-defined identifier for the text input.
      attr_reader :custom_id

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @style = :paragraph
        @value = data['value']
        @custom_id = data['custom_id']
      end

      # @!visibility private
      PLACEHOLDERS.each { |name| define_method(name) { nil } }
    end

    # A grouping of components with a contextual accessory.
    class Section
      # @return [Integer] the numeric identifier of the section.
      attr_reader :id

      # @return [Component] the contextual accessory of the section.
      attr_reader :accessory

      # @return [Array<Component>] the child components of the section.
      attr_reader :components

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @accessory = Components.from_data(data['accessory'], @bot)
        @components = data['components'].map { |component| Components.from_data(component, @bot) }
      end
    end

    # A content component representing message content.
    class TextDisplay
      # @return [Integer] the numeric identifier of the text display.
      attr_reader :id

      # @return [String] the content to be displayed for the text display.
      attr_reader :content

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @content = data['content']
      end
    end

    # A content component that compactly displays media.
    class Thumbnail
      # @return [Integer] the numeric identifier of the thumbnail.
      attr_reader :id

      # @return [MediaItem] the unfurled media content of the thumbnail.
      attr_reader :media

      # @return [true, false] whether or not the thumbnail's media should
      #   be blurred out.
      attr_reader :spoiler
      alias spoiler? spoiler

      # @return [String, nil] the alternative text for the thumbnail's media.
      attr_reader :description

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @spoiler = data['spoiler']
        @description = data['description']
        @media = MediaItem.new(data['media'], @bot)
      end
    end

    # A grouping of media attachments in an organized gallery format.
    class MediaGallery
      # @return [Integer] the numeric identifier of the media gallery.
      attr_reader :id

      # @return [Array<Item>] the media items contained within the media gallery.
      attr_reader :items

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @items = data['items'].map { |item| Item.new(item, @bot) }
      end

      # A singular media attachment.
      class Item
        # @return [MediaItem] the unfurled media content of the gallery item.
        attr_reader :media

        # @return [true, false] whether or not the gallery item's media should
        #   be blurred out.
        attr_reader :spoiler
        alias spoiler? spoiler

        # @return [String, nil] the alternative text for the gallery item's media.
        attr_reader :description

        # @!visibility private
        def initialize(data, bot)
          @bot = bot
          @spoiler = data['spoiler']
          @description = data['description']
          @media = MediaItem.new(data['media'], @bot)
        end
      end
    end

    # A component that adds vertical padding and visual division.
    class Separator
      # @return [Integer] the numeric identifier of the separator.
      attr_reader :id

      # @return [true, false] whether or not a visual divider should be displayed.
      attr_reader :divider
      alias divider? divider

      # @return [Integer] the size of the separator's padding. `1` for little padding,
      #   and `2` for big padding.
      attr_reader :spacing

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @divider = data['divider']
        @spacing = data['spacing']
      end
    end

    # A collection of components in an embed-like format.
    class Container
      # @return [Integer] the numeric identifier of the container.
      attr_reader :id

      # @return [ColourRGB, nil] the accent colour of the container.
      attr_reader :color
      alias colour color

      # @return [true, false] whether or not the container should be
      #   blurred out.
      attr_reader :spoiler
      alias spoiler? spoiler

      # @return [Array<Component>] the child components of the container.
      attr_reader :components

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @spoiler = data['spoiler']
        @color = ColourRGB.new(data['accent_color']) if data['accent_color']
        @components = data['components'].map { |component| Components.from_data(component, @bot) }
      end

      # Get the buttons contained within the container.
      # @return [Array<Button>] The buttons within the container.
      def buttons
        @components.flat_map do |component|
          case component
          when ActionRow
            component.buttons
          when Section
            component.accessory if component.accessory.is_a?(Button)
          end
        end.compact
      end
    end

    # A component that allows you to display an attachment.
    class File
      # @return [Integer] the numeric identifier of the file.
      attr_reader :id

      # @return [String] the name of the file that was uploaded.
      attr_reader :name

      # @return [Integer] the size of the file that was uploaded
      #   in bytes.
      attr_reader :size

      # @return [MediaItem] the unfurled media item of the file.
      attr_reader :media

      # @return [true, false] whether or not the file should be
      #   blurred out.
      attr_reader :spoiler
      alias spoiler? spoiler

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @name = data['name']
        @size = data['size']
        @spoiler = data['spoiler']
        @media = MediaItem.new(data['file'], @bot)
      end
    end

    # Resolved metadata about a piece of media.
    class MediaItem
      # @return [String] the URL to the media item.
      attr_reader :url

      # @return [Integer, nil] the width of the media item.
      attr_reader :width

      # @return [Integer, nil] the height of the media item.
      attr_reader :height

      # @return [String, nil] the proxied URL to the media item.
      attr_reader :proxy_url

      # @return [String, nil] the content type of the media item.
      attr_reader :content_type

      # @return [Integer, nil] the ID of the uploaded attachment. Only present
      #   when the media item was uploaded via an `attachment://<filename>` reference.
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

    # A parent component for interactive modal components.
    class Label
      # @return [Integer] the numeric identifier of the label.
      attr_reader :id

      # @return [Component] the interactive component of the label.
      attr_reader :component

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @component = Components.from_data(data['component'], @bot)
      end
    end

    # A surface that allows users to upload files in a modal.
    class FileUpload
      # @return [Integer] the numeric identifier of the file upload.
      attr_reader :id

      # @return [Array<Integer>] the IDs of the uploaded attachments.
      attr_reader :values

      # @return [String] the developer-defined identifier for the file upload.
      attr_reader :custom_id

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @custom_id = data['custom_id']
        @values = data['values'].map(&:to_i)
      end
    end

    # A grouping of radio buttons in a modal.
    class RadioGroup
      # @return [Integer] the numeric identifier of the radio group.
      attr_reader :id

      # @return [true, false] whether or not a radio button was selected.
      attr_reader :value
      alias value? value

      # @return [String] the developer-defined identifier for the radio group.
      attr_reader :custom_id

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @value = data['value']
        @custom_id = data['custom_id']
      end
    end

    # A grouping of checkboxes in a modal.
    class CheckboxGroup
      # @return [Integer] the numeric identifier of the checkbox group.
      attr_reader :id

      # @return [Array<String>] the values of the selected checkbox buttons.
      attr_reader :values

      # @return [String] the developer-defined identifier for the checkbox group.
      attr_reader :custom_id

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @values = data['values']
        @custom_id = data['custom_id']
      end
    end

    # A checkbox that can be ticked in a modal.
    class Checkbox
      # @return [Integer] the numeric identifier of the checkbox.
      attr_reader :id

      # @return [true, false] whether or not the checkbox was selected.
      attr_reader :value
      alias value? value

      # @return [String] the developer-defined identifier for the checkbox.
      attr_reader :custom_id

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id']
        @value = data['value']
        @custom_id = data['custom_id']
      end
    end
  end
end
