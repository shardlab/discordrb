# frozen_string_literal: true

module Discordrb
  # A server tag that a user has chosen to display on their profile.
  class PrimaryServer
    # @return [Integer] the ID of the server this primary server is for.
    attr_reader :server_id

    # @return [Boolean] if the user is displaying the primary server's tag.
    attr_reader :enabled
    alias_method :enabled?, :enabled

    # @return [String] the text of the primary server's tag. Limited to four characters.
    attr_reader :name
    alias_method :text, :name

    # @return [String] the ID of the server tag's badge. can be used to generate a badge URL.
    # @see #badge_url
    attr_reader :badge_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @server_id = data['identity_guild_id']&.to_i
      @enabled = data['identity_enabled']
      @name = data['tag']
      @badge_id = data['badge']
    end

    # Get the server associated with this primary server.
    # @return [Server] the server associated with this primary server.
    # @raise [Discordrb::Errors::NoPermission] this can happen when the bot is not in the associated server.
    def server
      @bot.server(@server_id)
    end

    # Utility method to get a server tag's badge URL.
    # @param format [String] the URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @return [String] the URL to the server tag's badge image.
    def badge_url(format = 'webp')
      API.server_tag_badge_url(@server_id, @badge_id, format)
    end

    # Comparison based off of server ID.
    def ==(other)
      return false unless other.is_a?(PrimaryServer)

      Discordrb.id_compare(other.server_id, @server_id)
    end
  end
end
