# frozen_string_literal: true

module Discordrb
  # The welcome screen shown to new members in a server.
  class WelcomeScreen
    # @return [Server] the server this welcome screen is for.
    attr_reader :server

    # @return [String] the server description shown in the welcome screen.
    attr_reader :description

    # @return [Array<WelcomeChannel>] channels linked in the welcome screen.
    attr_reader :channels

    # @!visibility private
    def initialize(data, server, bot)
      @bot = bot
      @server = server
      from_other(data)
    end

    # Set whether this welcome screen is enabled or not.
    # @param enabled [true, false] whether the welcome screen is enabled or not.
    def enabled=(enabled)
      update_data(enabled: enabled)
    end

    # Set the description of the welcome screen.
    # @param description [String] the new description of the welcome screen.
    def description=(description)
      update_data(description: description)
    end

    # Set the channels of the welcome screen.
    # @param channels [Array<Hash>] the new welcome channels to set.
    def channels=(channels)
      update_data(channels: channels.to_a.map(&:to_h))
    end

    # Remove one or more prompts from the welcome screen.
    # @param ids [Integer, String] the IDs of the welcome channels to remove.
    def delete_channels(*ids)
      channels = @channels.reject do |channel|
        [*ids].map(&:resolve_id).any?(channel.id)
      end

      update_data(channels: channels.map(&:to_h))
    end

    alias_method :delete_channel, :delete_channels

    # Get a welcome channel by its channel ID.
    # @param id [Integer, String, Channel, WelcomeChannel] the ID of the channel to find.
    # @return [WelcomeChannel, nil] the welcome channel, or `nil` if it couldn't be found.
    def channel(id)
      @channels.find { |welcome| welcome.channel.id == id.resolve_id }
    end

    # Add a welcome channel to the welcome screen.
    # @param channel [Channel, Integer, String] the channel the welcome channel references.
    # @param description [String] the description to show for the welcome channel.
    # @param emoji [Emoji, String, Integer, Hash, nil] An emoji, its ID, or a unicode emoji to display alongside the channel.
    def create_channel(channel, description:, emoji: nil)
      emoji = case emoji
              when Integer, String
                emoji.to_i.positive? ? { emoji_id: emoji } : { emoji_name: emoji }
              when Emoji, Reaction
                emoji.id.nil? ? { emoji_name: emoji.name } : { emoji_id: emoji.id }
              end

      update_data(channels: (@channels.map(&:to_h) << { channel_id: channel.resolve_id,
                                                        description: description, **emoji }))
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

    # A welcome channel and its display options within a welcome screen.
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
        @emoji = if data['emoji_id']
                   bot.emoji(data['emoji_id'])
                 elsif data['emoji_name']
                   Emoji.new({ 'name' => data['emoji_name'], 'animated' => false }, bot)
                 end
      end

      # @!visibility private
      def to_h
        {
          channel_id: @channel.id,
          description: @description,
          emoji_name: @emoji&.name,
          emoji_id: @emoji&.id
        }
      end
    end
  end
end
