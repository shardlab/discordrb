# frozen_string_literal: true

require 'discordrb/api'
require 'discordrb/api/invite'
require 'discordrb/api/user'
require 'discordrb/light/data'
require 'discordrb/light/integrations'

# This module contains classes to allow connections to bots without a connection to the gateway socket, i.e. bots
# that only use the REST part of the API.
module Discordrb::Light
  # A bot that only uses the REST part of the API. Hierarchically unrelated to the regular {Discordrb::Bot}. Useful to
  # make applications integrated to Discord over OAuth, for example.
  class LightBot
    # @!visibility private
    # @return [API::Client]
    attr_reader :client

    # Create a new LightBot. This does no networking yet, all networking is done by the methods on this class.
    # @param token [String] The token that should be used to authenticate to Discord. Can be an OAuth token or a regular
    #   user account token.
    def initialize(token)
      if token.respond_to? :token
        # Parse AccessTokens from the OAuth2 gem
        token = token.token
      end

      unless token.include? '.'
        # Discord user/bot tokens always contain two dots, so if there's none we can assume it's an OAuth token.
        token = "Bearer #{token}" # OAuth tokens have to be prefixed with 'Bearer' for Discord to be able to use them
      end

      @client = Discordrb::API::Client.new(token)
    end

    # @return [LightProfile] the details of the user this bot is connected to.
    def profile
      response = @client.get_current_user
      LightProfile.new(response, self)
    end

    # @return [Array<LightGuild>] the guilds this bot is connected to.
    def guilds
      @client.get_current_user_guilds.map { |e| LightGuild.new(e, self) }
    end

    # Gets the connections associated with this account.
    # @return [Array<Connection>] this account's connections.
    def connections
      @client.get_current_user_connections.map { |data| Connection.new(data, self) }
    end
  end
end
