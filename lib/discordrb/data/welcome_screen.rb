# frozen_string_literal: true

module Discordrb
  # The welcome screen shown to new members in a server.
  class WelcomeScreen
    # @return [Server] the server this welcome screen is for.
    attr_reader :server

    # @return [String] the server description shown in the welcome screen.
    attr_reader :description

    # @return [Array<WelcomeChannel>] channels linked in the welcome screen and their display options.
    attr_reader :channels

    # @!visibility private
    def initialize(data, server, bot)
      @bot = bot
      @server = server
      from_other(data)
    end

    # Get a welcome channel by its channel ID.
    # @param id [Integer, String] the ID of the channel to find.
    # @return [WelcomeChannel, nil] the welcome channel, or nil if it couldn't be found.
    def channel(id)
      channels.find { |chan| chan.channel.id == id.resolve_id }
    end

    # Set the description of the welcome screen.
    # @param description [String] the new description of the welcome screen.
    def description=(description)
      update_data(description: description)
    end

    # Set whether this welcome screen is enabled or not.
    # @param enabled [true, false] whether the welcome screen is enabled or not.
    def enabled=(enabled)
      update_data(enabled: enabled)
    end

    # @!visibility private
    def from_other(new_data)
      @description = new_data['description']
      @channels = new_data['welcome_channels'].map { |channel| WelcomeChannel.new(channel, @bot) }
    end

    # @!visibility private
    def update_data(new_data)
      from_other(JSON.parse(API::Server.modify_welcome_screen(@bot.token, server.id,
                                                              new_data.key?(:enabled) ? new_data[:enabled] : :undef,
                                                              new_data.key?(:channels) ? new_data[:channels]&.to_a : :undef,
                                                              new_data.key?(:description) ? new_data[:description] : :undef)))
    end

    # Channels and their display options inside of a welcome screen.
    class WelcomeChannel
      # @return [String] the description shown for this channel.
      attr_reader :description

      # @return [Channel] the channel this welcome channel represents.
      attr_reader :channel

      # @return [Emoji, nil] the emoji shown for this welcome channel.
      attr_reader :emoji

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @description = data['description']
        @channel = bot.channel(data['channel_id'])
        @emoji = bot.emoji(data['emoji_id']) if data['emoji_id']
        @emoji = Emoji.new({ 'name' => data['emoji_name'], 'animated' => false }, bot) if data['emoji_name']
      end
    end
  end
end
