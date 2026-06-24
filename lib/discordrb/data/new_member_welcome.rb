# frozen_string_literal: true

module Discordrb
  # Represents the server guide for a server.
  class NewMemberWelcome
    # @return [Server] the server for the new member experience.
    attr_reader :server

    # @return [true, false] if the new member experience is enabled.
    attr_reader :enabled
    alias enabled? enabled

    # @return [Array<Action>] the actions new server members should complete.
    attr_reader :actions

    # @return [WelcomeMessage] the welcome message shown to new server members.
    attr_reader :welcome_message

    # @return [Array<ResourceChannel>] the resource channels for new server members.
    attr_reader :resource_channels

    # @!visibility private
    def initialize(data, server, bot)
      @bot = bot
      @server = server
      @enabled = data['enabled']
      @actions = data['new_member_actions'].map { |key| Action.new(key, self, @bot) }
      @welcome_message = WelcomeMessage.new(data['welcome_message'] || {}, self, @bot)
      @resource_channels = data['resource_channels'].map { |key| ResourceChannel.new(key, self, @bot) }
    end

    # Check if the new member experience is equivalent to another one.
    # @param other [HomeSettings] The new member experience to compare against.
    # @return [true, false] If the new member experiences are equivalent to one another.
    def ==(other)
      other.is_a?(HomeSettings) ? @server == other.server : false
    end

    # Get the hash of the banner for the new member experience.
    # @return [String, nil] The hash of the banner for the new member exerpeice, or `nil`.
    def banner_id
      @server.home_banner_id
    end

    # Utility method to get a URL to the banner of the new member experience.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @param size [Integer, nil] The URL will default to `4096`. You can otherwise specify any number that's a power of two to override this.
    # @return [String, nil] The URL to the banner of the new member experience, or `nil` if the new member experience doesn't have a banner set.
    def banner_url(format: 'webp', size: nil)
      @server.home_banner_url(format: format, size: size)
    end

    alias_method :eql?, :==

    # Represents the message shown to new members.
    class WelcomeMessage
      # @return [String] the content of the welcome message.
      attr_reader :content

      # @return [Array<Integer>] the author IDs of the welcome message.
      attr_reader :author_ids

      # @!visibility private
      def initialize(data, home, bot)
        @bot = bot
        @home = home
        @content = data['message'] || ''
        @author_ids = data['author_ids']&.map(&:to_i) || []
      end

      # Get the authors of the welcome message.
      # @return [Array<User>] The authors of the welcome message.
      def authors
        @authors ||= @author_ids.filter_map { |id| @bot.user(id) }
      end

      # Check if the welcome message is equivalent to another one.
      # @param other [WelcomeMessage] The welcome message to compare against.
      # @return [true, false] If the welcome messages are equivalent to each other.
      def ==(other)
        return false unless other.is_a?(WelcomeMessage)

        @content == other.content && @author_ids == other.author_ids
      end

      alias_method :eql?, :==
    end

    # Represents a read-only resource channel.
    class ResourceChannel
      # @return [String] the title of the resource channel.
      attr_reader :title

      # @return [String, nil] the icon of the resource channel.
      attr_reader :icon_id

      # @return [String] the description of the resource channel.
      attr_reader :description

      # @!visibility private
      def initialize(data, home, bot)
        @bot = bot
        @home = home
        @title = data['title']
        @icon_id = data['icon']
        @channel_id = data['channel_id']
        @description = data['description'] || ''
        @emoji = Emoji.new(data['emoji'], @bot) if data['emoji']
      end

      # Get the underlying channel the resource channel references.
      # @return [Channel] The channel that the resource channel references.
      def channel
        @channel ||= @bot.channel(@channel_id)
      end

      # Get the emoji of the resource channel.
      # @return [Emoji, nil] The emoji of the resource channel, or `nil`.
      def emoji
        @emoji&.id ? @home.server.emojis[@emoji.id] : @emoji
      end

      # Check if the resource channel is equivalent to another one.
      # @param other [ResourceChannel] The resource channel to compare against.
      # @return [true, false] If the resource channels are equivalent to one another.
      def ==(other)
        other.is_a?(ResourceChannel) ? channel == other.channel : false
      end

      alias_method :eql?, :==

      # Utility method to get a resource channel's icon URL.
      # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
      # @param size [Integer, nil] The URL will default to `4096`. You can otherwise specify any number that's a power of two to override this.
      # @return [String, nil] The URL to the resource channel's icon, or `nil` if the resource channel doesn't have an icon set.
      def icon_url(format: 'webp', size: nil)
        API.resource_channel_icon_url(@channel_id, @icon_id, format, size) if @icon_id
      end
    end

    # Represents an action a new member must complete.
    class Action
      # Mapping of action types.
      TYPES = {
        view: 0,
        talk: 1
      }.freeze

      # @return [Integer] the type of the new member action.
      attr_reader :type

      # @return [String] the title of the new member action.
      attr_reader :title

      # @return [String, nil] the icon of the new member action.
      attr_reader :icon_id

      # @return [String] the description of the new member action.
      attr_reader :description

      # @!visibility private
      def initialize(data, home, bot)
        @bot = bot
        @home = home
        @title = data['title']
        @type = data['action_type']
        @icon_id = data['icon']
        @channel_id = data['channel_id']
        @description = data['description'] || ''
        @emoji = Emoji.new(data['emoji'], @bot) if data['emoji']
      end

      # Get the channel where the new member action should be completed.
      # @return [Channel] The channel where the action should be completed.
      def channel
        @channel ||= @bot.channel(@channel_id)
      end

      # Get the emoji of the new member action.
      # @return [Emoji, nil] The emoji of the new member action, or `nil`.
      def emoji
        @emoji&.id ? @home.server.emojis[@emoji.id] : @emoji
      end

      # Check if the new member action is equivalent to another one.
      # @param other [Action] The new member action to compare against.
      # @return [true, false] If the new member actions are equivalent to one another.
      def ==(other)
        other.is_a?(Action) ? channel == other.channel : false
      end

      alias_method :eql?, :==

      # @!method view?
      #   @return [true, false] if the member must view the channel to complete the action.
      # @!method talk?
      #   @return [true, false] if the member must send a message in the channel to complete the action.
      TYPES.each do |name, value|
        define_method("#{name}?") { @type == value }
      end

      # Utility method to get a new member action's icon URL.
      # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
      # @param size [Integer, nil] The URL will default to `4096`. You can otherwise specify any number that's a power of two to override this.
      # @return [String, nil] The URL to the new member action's icon, or `nil` if the new member action doesn't have an icon set.
      def icon_url(format: 'webp', size: nil)
        API.new_member_action_icon_url(@channel_id, @icon_id, format, size) if @icon_id
      end
    end
  end
end
