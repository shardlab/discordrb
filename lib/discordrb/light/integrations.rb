# frozen_string_literal: true

require 'discordrb/data'
require 'discordrb/light/data'

module Discordrb::Light
  # A connection of your Discord account to a particular other service (currently, Twitch and YouTube)
  class Connection
    # @return [Symbol] what type of connection this is (either :twitch or :youtube currently)
    attr_reader :type

    # @return [true, false] whether this connection is revoked
    attr_reader :revoked
    alias_method :revoked?, :revoked

    # @return [String] the name of the connected account
    attr_reader :name

    # @return [String] the ID of the connected account
    attr_reader :id

    # @return [Array<Integration>] the integrations associated with this connection
    attr_reader :integrations

    # @!visibility private
    def initialize(data, bot)
      @bot = bot

      @revoked = data['revoked']
      @type = data['type'].to_sym
      @name = data['name']
      @id = data['id']

      @integrations = data['integrations'].map { |e| Integration.new(e, self, bot) }
    end
  end

  # An integration of a connection into a particular guild, for example being a member of a subscriber-only Twitch
  # guild.
  class Integration
    include Discordrb::IDObject

    # @return [UltraLightGuild] the guild associated with this integration
    attr_reader :guild

    # @note The connection returned by this method will have no integrations itself, as Discord doesn't provide that
    #   data. Also, it will always be considered not revoked.
    # @return [Connection] the guild's underlying connection (for a Twitch subscriber-only guild, it would be the
    #   Twitch account connection of the guild owner).
    attr_reader :guild_connection

    # @return [Connection] the connection integrated with the guild (i.e. your connection)
    attr_reader :integrated_connection

    # @!visibility private
    def initialize(data, integrated, bot)
      @bot = bot
      @integrated_connection = integrated

      @guild = UltraLightGuild.new(data['guild'], bot)

      # Restructure the given data so we can reuse the Connection initializer
      restructured = {}

      restructured['type'] = data['type']
      restructured['id'] = data['account']['id']
      restructured['name'] = data['account']['name']
      restructured['integrations'] = []

      @guild_connection = Connection.new(restructured, bot)
    end
  end
end
