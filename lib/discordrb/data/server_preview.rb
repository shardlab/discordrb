# frozen_string_literal: true

module Discordrb
  # Publicly accessible information about a discoverable server.
  class ServerPreview
    include IDObject
    include ServerAttributes

    # @return [String, nil] the ID of the server's invite splash screen.
    # @see #splash_url
    attr_reader :splash_id

    # @return [String, nil] the ID of the server's discovery splash screen.
    # @see #discovery_splash_url
    attr_reader :discovery_splash_id

    # @return [Hash<Integer => Emoji>] a hash of all the emojis usable on this server.
    attr_reader :emojis

    # @return [Array<Symbol>] the features of this server, e.g. `:banner` or `:verified`.
    attr_reader :features

    # @return [Integer] the approximate number of members on this server, offline or not.
    attr_reader :member_count

    # @return [Integer] the approximate number of members that aren't offline on this server.
    attr_reader :presence_count

    # @return [String, nil] the description of this server that's shown in the discovery tab.
    attr_reader :description

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      @icon_id = data['icon']
      @splash_id = data['splash']
      @description = data['description']
      @discovery_splash_id = data['discovery_splash']
      @member_count = data['approximate_member_count']
      @presence_count = data['approximate_presence_count']
      @features = data['features'].map { |feature| feature.downcase.to_sym }
      @emojis = data['emojis'].to_h { |emoji| [emoji['id'].to_i, Emoji.new(emoji, bot)] }
    end

    # Get the server associated with this server preview.
    # @return [Server] the server associated with this server preview.
    # @raise [Discordrb::Errors::NoPermission] this can happen when the bot is not in the associated server.
    def server
      @bot.server(@id)
    end

    # Utility method to get a server preview's splash URL.
    # @param format [String] the URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @return [String, nil] the URL to the server's splash image, or `nil` if the server doesn't have a splash image.
    def splash_url(format = 'webp')
      API.splash_url(@id, @splash_id, format) if @splash_id
    end

    # Utility method to get a server preview's discovery splash URL.
    # @param format [String] the URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @return [String, nil] the URL to the server's discovery splash image, or `nil` if the server doesn't have a discovery splash image.
    def discovery_splash_url(format = 'webp')
      API.discovery_splash_url(@id, @discovery_splash_id, format) if @discovery_splash_id
    end
  end
end
