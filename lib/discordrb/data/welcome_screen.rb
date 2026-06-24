# frozen_string_literal: true

module Discordrb
  # The welcome screen of a server.
  class WelcomeScreen
    # @return [Server] the server of the welcome screen.
    attr_reader :server

    # @return [Array<WelcomeChannel>] the welcome channels of the welcome screen.
    attr_reader :channels

    # @return [String] the welcome message of the welcome screen; 1-140 characters.
    attr_reader :description

    # @!visibility private
    def initialize(data, server, bot)
      @bot = bot
      @server = server
      update_data(data)
    end

    # Get a welcome channel associated with the welcome screen.
    # @param channel_id [Integer, String, Channel] The ID of the welcome channel to find.
    # @return [WelcomeChannel, nil] The channel that was found, or `nil` if it wasn't found.
    def channel(channel_id)
      channel_id = channel_id.resolve_id

      @channels.find { |entity| entity.channel.id == channel_id }
    end

    # Create a welcome channel for the welcome screen.
    # @param channel [Channel, Integer, String] The channel to reference.
    # @param description [String] The description of the welcome channel.
    # @param emoji [Emoji, Integer, String, nil] The emoji of the welcome channel.
    # @param reason [String, nil] The reason to show in the audit log for creating the channel.
    # @return [nil]
    def add_channel(channel:, description:, emoji: nil, reason: nil)
      channel_data = {
        description: description,
        channel_id: channel.resolve_id,
        **Emoji.build_emoji_hash(emoji)
      }

      modify(channels: @channels.dup << channel_data, reason: reason)
    end

    alias_method :create_channel, :add_channel

    # Modify the properties of the welcome screen.
    # @param enabled [true, false, nil] Whether or not the welcome screen should be enabled.
    # @param channels [Array<#to_h>, nil] The new welcome channels to set for the welcome screen.
    # @param description [String, nil] The new description of the welcome screen; 1-140 characters.
    # @param reason [String, nil] The reason to show in the audit log for updating the welcome screen.
    # @return [nil]
    def modify(enabled: :undef, channels: :undef, description: :undef, reason: nil)
      data = {
        reason: reason,
        enabled: enabled,
        description: description,
        welcome_channels: channels == :undef ? channels : channels&.to_a&.map(&:to_h)
      }

      update_data(JSON.parse(API::Server.update_welcome_screen(@bot.token, @server.id, **data)))
      nil
    end

    # Check if the welcome screen is equal to another welcome screen.
    # @param other [WelcomeScreen, nil] The object to compare this one against.
    # @return [true, false] Whether or not the welcome screen is equal to the other object.
    def ==(other)
      other.is_a?(WelcomeScreen) ? other.server == @server : false
    end

    alias_method :eql?, :==

    # @!visibility private
    def inspect
      "<WelcomeScreen channels=#{@channels.inspect} description=\"#{@description}\">"
    end

    private

    # @!visibility private
    def update_data(new_data)
      @description = new_data['description']

      if @channels
        old_channels = @channels

        @channels = new_data['welcome_channels'].map do |data|
          if (old_channel = old_channels.find { |old| old.channel.id == data['channel_id'].to_i })
            old_channel.tap { old_channel.update_data(data) }
          else
            WelcomeChannel.new(data, self, @bot)
          end
        end
      else
        @channels = new_data['welcome_channels'].map { |data| WelcomeChannel.new(data, self, @bot) }
      end
    end

    # A welcome channel within a welcome screen.
    class WelcomeChannel
      # @return [Channel] the channel of the welcome channel.
      attr_reader :channel

      # @return [String] the description of the welcome channel.
      attr_reader :description

      # @!visibility private
      def initialize(data, screen, bot)
        @bot = bot
        @screen = screen
        update_data(data)
      end

      # Get the emoji of the welcome channel.
      # @return [Emoji, nil] The emoji of the welcome channel.
      def emoji
        @emoji_id ? @channel.server.emojis[@emoji_id] : @emoji_name
      end

      # Modify the properties of the welcome channel.
      # @param description [String] The new description of the welcome channel; 1-52 characters.
      # @param emoji [Emoji, Integer, String, Reaction, nil] The new emoji of the welcome channel.
      # @param reason [String, nil] The reason to show in the server's audit for modifying the channel.
      # @return [nil]
      def modify(description: :undef, emoji: :undef, reason: nil)
        channel_data = {
          channel_id: @channel.resolve_id,
          **(Emoji.build_emoji_hash(emoji) if emoji != :undef),
          description: description == :undef ? @description : description
        }

        channel_data.merge!(Emoji.build_emoji_hash(self.emoji)) if emoji == :undef

        channels = @screen.channels.dup.tap { |array| array.delete(self) }

        @screen.modify(channels: channels << channel_data, reason: reason)
      end

      # Check if the welcome channel is equal to another welcome channel.
      # @param other [WelcomeChannel, nil] The object to compare this one against.
      # @return [true, false] Whether or not the welcome channel is equal to the other object.
      def ==(other)
        other.is_a?(WelcomeChannel) ? other.channel == @channel : false
      end

      alias_method :eql?, :==

      # @!visibility private
      def to_h
        {
          channel_id: @channel.id,
          description: @description,
          **Emoji.build_emoji_hash(emoji)
        }
      end

      # @!visibility private
      def inspect
        "<WelcomeChannel id=#{@channel.id} description=\"#{@description}\">"
      end

      # @!visibility private
      def update_data(new_data)
        @emoji_id = new_data['emoji_id']
        @description = new_data['description']
        @channel = @bot.channel(new_data['channel_id'])
        @emoji_name = new_data['emoji_name'] ? Emoji.new({ 'name' => new_data['emoji_name'] }, @bot) : nil
      end
    end
  end
end
