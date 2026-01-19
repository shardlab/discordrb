# frozen_string_literal: true

module Discordrb
  # Integration Account
  class IntegrationAccount
    include IDObject

    # @return [String] this account's name.
    attr_reader :name

    # @!visibility private
    def initialize(data)
      @id = data['id'].to_i
      @name = data['name']
    end
  end

  # Bot/OAuth2 application for discord integrations
  class IntegrationApplication
    include IDObject

    # @return [String] the name of the application.
    attr_reader :name

    # @return [String, nil] the icon hash of the application.
    attr_reader :icon

    # @return [String] the description of the application.
    attr_reader :description

    # @return [User, nil] the bot associated with this application.
    attr_reader :bot

    # @!visibility private
    def initialize(data, bot)
      @id = data['id'].to_i
      @name = data['name']
      @icon = data['icon']
      @description = data['description']
      @bot = bot.ensure_user(data['bot']) if data['bot']
    end
  end

  # Server integration
  class Integration
    include IDObject

    # Map of expire behaviors.
    EXPIRE_BEHAVIORS = {
      remove: 0,
      kick: 1
    }.freeze

    # @return [String] the integration name
    attr_reader :name

    # @return [Server] the server the integration is linked to
    attr_reader :server

    # @return [User, nil] the user who added the integration to the server. This will be `nil`
    #  for very old integrations, or if the integration was sent via a Gateway event.
    attr_reader :user

    # @return [Integer, nil] the ID of the role that this integration uses for "subscribers"
    attr_reader :role_id

    # @return [true, false] whether or not emoticons are enabled
    attr_reader :emoticon
    alias_method :emoticon?, :emoticon
    alias_method :emoticons?, :emoticon

    # @return [String] the integration type (YouTube, Twitch, Discord, etc.)
    attr_reader :type

    # @return [true, false] whether the integration is enabled
    attr_reader :enabled
    alias_method :enabled?, :enabled

    # @return [true, false] whether or not the integration is syncing
    attr_reader :syncing
    alias_method :syncing?, :syncing

    # @return [IntegrationAccount] the integration account information
    attr_reader :account

    # @return [Time, nil] the time the integration was last synced at
    attr_reader :synced_at

    # @return [Symbol, nil] the behaviour of expiring subscribers. When this is `:remove`, the
    #  associated role will be removed from the user. When this is `:kick`, the user will be
    #  kicked out of the server
    attr_reader :expire_behaviour
    alias_method :expire_behavior, :expire_behaviour

    # @return [Integer] the grace period before subscribers expire (in days)
    attr_reader :expire_grace_period

    # @return [Integer, nil] how many subscribers this integration has.
    attr_reader :subscriber_count

    # @return [true, false] whether or not this integration been revoked.
    attr_reader :revoked
    alias_method :revoked?, :revoked

    # @return [IntegrationApplication, nil] the application for the integration.
    attr_reader :application

    # @return [Array<String>] the oauth2 scopes the application has been authorized for
    attr_reader :scopes

    # @!visibility private
    def initialize(data, bot, server)
      @bot = bot
      @server = server
      @id = data['id'].to_i
      @name = data['name']
      @enabled = data['enabled']
      @syncing = data['syncing'] || false
      @type = data['type']
      @account = IntegrationAccount.new(data['account'])
      @synced_at = Time.parse(data['synced_at']) if data['synced_at']
      @expire_behaviour = EXPIRE_BEHAVIORS.key(data['expire_behavior']) if data['expire_behavior']
      @expire_grace_period = data['expire_grace_period'] || 0
      @user = @bot.ensure_user(data['user']) if data['user']
      @role_id = data['role_id']&.to_i
      @emoticon = data['enable_emoticons'] || false
      @subscriber_count = data['subscriber_count']&.to_i
      @revoked = data['revoked'] || false
      @application = IntegrationApplication.new(data['application'], bot) if data['application']
      @scopes = data['scopes'] || []
    end

    # Get the role that this integration uses for subscribers.
    # @return [Role, nil] The role that this integration uses for subscribers.
    def subscriber_role
      @server.role(@role_id) if @role_id
    end

    # The inspect method is overwritten to give more useful output.
    def inspect
      "<Integration name=\"#{@name}\" id=#{@id} type=\"#{@type}\" enabled=#{@enabled}>"
    end
  end
end
