# frozen_string_literal: true

module Discordrb
  # Mixin for the attributes users should have
  module UserAttributes
    # rubocop:disable Naming/VariableNumber
    FLAGS = {
      staff: 1 << 0,
      partner: 1 << 1,
      hypesquad: 1 << 2,
      bug_hunter_level_1: 1 << 3,
      hypesquad_online_house_1: 1 << 6,
      hypesquad_online_house_2: 1 << 7,
      hypesquad_online_house_3: 1 << 8,
      premium_early_supporter: 1 << 9,
      team_pseudo_user: 1 << 10,
      bug_hunter_level_2: 1 << 14,
      verified_bot: 1 << 16,
      verified_developer: 1 << 17,
      certified_moderator: 1 << 18,
      bot_http_interactions: 1 << 19,
      active_developer: 1 << 22
    }.freeze
    # rubocop:enable Naming/VariableNumber

    # @return [String] this user's username
    attr_reader :username
    alias_method :name, :username

    # @return [String, nil] this user's global name
    attr_reader :global_name

    # @return [String] this user's discriminator which is used internally to identify users with identical usernames.
    attr_reader :discriminator
    alias_method :discrim, :discriminator
    alias_method :tag, :discriminator
    alias_method :discord_tag, :discriminator

    # @return [true, false] whether this user is a Discord bot account
    attr_reader :bot_account
    alias_method :bot_account?, :bot_account

    # @return [true, false] whether this is fake user for a webhook message
    attr_reader :webhook_account
    alias_method :webhook_account?, :webhook_account
    alias_method :webhook?, :webhook_account

    # @return [String] the ID of this user's current avatar, can be used to generate an avatar URL.
    # @see #avatar_url
    attr_accessor :avatar_id

    # @return [true, false] whether the user is an offical Discord System user (part of the urgent message system).
    attr_reader :system_account
    alias_method :system_account?, :system_account

    # @return [AvatarDecoration, nil] the current user's avatar decoration, or nil if the user doesn't have one.
    attr_reader :avatar_decoration

    # @return [Collectibles] the collectibles that this user has collected.
    attr_reader :collectibles

    # @return [PrimaryServer, nil] the server tag the user has adopted, or nil if the user doesn't have one displayed.
    attr_reader :primary_server
    alias_method :server_tag, :primary_server

    # Utility function to get Discord's display name of a user not in server
    # @return [String] the name the user displays as (global_name if they have one, username otherwise)
    def display_name
      global_name || username
    end

    # Utility function to mention users in messages
    # @return [String] the mention code in the form of <@id>
    def mention
      "<@#{@id}>"
    end

    # Utility function to get Discord's distinct representation of a user, i.e. username + discriminator
    # @return [String] distinct representation of user
    # TODO: Maybe change this method again after discriminator removal ?
    def distinct
      if @discriminator && @discriminator != '0'
        "#{@username}##{@discriminator}"
      else
        @username.to_s
      end
    end

    # Utility function to get a user's avatar URL.
    # @param format [String, nil] If `nil`, the URL will default to `webp` for static avatars, and will detect if the user has a `gif` avatar. You can otherwise specify one of `webp`, `jpg`, `png`, or `gif` to override this. Will always be PNG for default avatars.
    # @return [String] the URL to the avatar image.
    # TODO: Maybe change this method again after discriminator removal ?
    def avatar_url(format = nil)
      unless @avatar_id
        return API::User.default_avatar(@discriminator, legacy: true) if @discriminator && @discriminator != '0'

        return API::User.default_avatar(@id)
      end

      API::User.avatar_url(@id, @avatar_id, format)
    end

    # @return [Integer] the public flags on a user's account
    attr_reader :public_flags

    FLAGS.each do |name, value|
      define_method("#{name}?") do
        @public_flags.anybits?(value)
      end
    end

    # Utility function to get a user's banner URL.
    # @param format [String, nil] If `nil`, the URL will default to `png` for static banners and will detect if the user has a `gif` banner.
    # You can otherwise specify one of `webp`, `jpg`, `png`, or `gif` to override this.
    # @return [String, nil] the URL to the banner image or nil if the user doesn't have one.
    def banner_url(format = nil)
      API::User.banner_url(@id, banner_id, format) if banner_id
    end
  end

  # User on Discord, including internal data like discriminators
  class User
    include IDObject
    include UserAttributes

    # @return [Symbol] the current online status of the user (`:online`, `:offline` or `:idle`)
    attr_reader :status

    # @return [ActivitySet] the activities of the user
    attr_reader :activities

    # @return [Hash<Symbol, Symbol>] the current online status (`:online`, `:idle` or `:dnd`) of the user
    #   on various device types (`:desktop`, `:mobile`, or `:web`). The value will be `nil` if the user is offline or invisible.
    attr_reader :client_status

    # @!visibility private
    def initialize(data, bot)
      @bot = bot

      @username = data['username']
      @global_name = data['global_name']
      @id = data['id'].to_i
      @discriminator = data['discriminator']
      @avatar_id = data['avatar']
      @activities = Discordrb::ActivitySet.new
      @public_flags = data['public_flags'] || 0
      @bot_account = data['bot'] || false
      @webhook_account = data['_webhook'] || false

      @status = :offline
      @client_status = process_client_status(data['client_status'])
      @banner_id = data['banner']
      @system_account = data['system'] || false
      @avatar_decoration = process_avatar_decoration(data['avatar_decoration_data'])
      @collectibles = Collectibles.new(data['collectibles'] || {}, bot)

      @primary_server = process_primary_server(data['primary_guild'] || {})
    end

    # Get a user's PM channel or send them a PM
    # @overload pm
    #   Creates a private message channel for this user or returns an existing one if it already exists
    #   @return [Channel] the PM channel to this user.
    # @overload pm(content)
    #   Sends a private to this user.
    #   @param content [String] The content to send.
    #   @return [Message] the message sent to this user.
    def pm(content = nil)
      if content
        # Recursively call pm to get the channel, then send a message to it
        channel = pm
        channel.send_message(content)
      else
        # If no message was specified, return the PM channel
        @bot.pm_channel(@id)
      end
    end

    alias_method :dm, :pm

    # Send the user a file.
    # @param file [File] The file to send to the user
    # @param caption [String] The caption of the file being sent
    # @param filename [String] Overrides the filename of the uploaded file
    # @param spoiler [true, false] Whether or not this file should appear as a spoiler.
    # @return [Message] the message sent to this user.
    # @example Send a file from disk
    #   user.send_file(File.open('rubytaco.png', 'r'))
    def send_file(file, caption = nil, filename: nil, spoiler: nil)
      pm.send_file(file, caption: caption, filename: filename, spoiler: spoiler)
    end

    # @return [String, nil] the ID of this user's current banner, can be used to generate a banner URL.
    # @see #banner_url
    def banner_id
      @banner_id ||= JSON.parse(API::User.resolve(@bot.token, @id))['banner']
    end

    # Set the user's username
    # @note for internal use only
    # @!visibility private
    def update_username(username)
      @username = username
    end

    # Set the user's global_name
    # @note For internal use only.
    # @!visibility private
    def update_global_name(global_name)
      @global_name = global_name
    end

    # Set the user's avatar_decoration
    # @note For internal use only.
    # @!visibility private
    def update_avatar_decoration(decoration)
      @avatar_decoration = process_avatar_decoration(decoration)
    end

    # Set the user's collectibles
    # @note For internal use only.
    # @!visibility private
    def update_collectibles(collectibles)
      @collectibles = Collectibles.new(collectibles || {}, @bot)
    end

    # Set the user's primary server
    # @note For internal use only.
    # @!visibility private
    def update_primary_server(server)
      @primary_server = process_primary_server(server || {})
    end

    # Set the user's presence data
    # @note for internal use only
    # @!visibility private
    def update_presence(data)
      @status = data['status'].to_sym
      @client_status = process_client_status(data['client_status'])

      @activities = Discordrb::ActivitySet.new(data['activities'].map { |act| Activity.new(act, @bot) })
    end

    # Add an await for a message from this user. Specifically, this adds a global await for a MessageEvent with this
    # user's ID as a :from attribute.
    # @see Bot#add_await
    def await(key, attributes = {}, &block)
      @bot.add_await(key, Discordrb::Events::MessageEvent, { from: @id }.merge(attributes), &block)
    end

    # Add a blocking await for a message from this user. Specifically, this adds a global await for a MessageEvent with this
    # user's ID as a :from attribute.
    # @see Bot#add_await!
    def await!(attributes = {}, &block)
      @bot.add_await!(Discordrb::Events::MessageEvent, { from: @id }.merge(attributes), &block)
    end

    # Gets the member this user is on a server
    # @param server [Server] The server to get the member for
    # @return [Member] this user as a member on a particular server
    def on(server)
      id = server.resolve_id
      @bot.server(id).member(@id)
    end

    # Is the user the bot?
    # @return [true, false] whether this user is the bot
    def current_bot?
      @bot.profile.id == @id
    end

    # @!visibility private
    def process_client_status(client_status)
      (client_status || {}).to_h { |k, v| [k.to_sym, v.to_sym] }
    end

    # @!visibility private
    def process_avatar_decoration(decoration)
      decoration ? AvatarDecoration.new(decoration, @bot) : nil
    end

    # @!visibility private
    def process_primary_server(server)
      PrimaryServer.new(server, @bot) if server['identity_enabled']
    end

    # @!method offline?
    #   @return [true, false] whether this user is offline.
    # @!method idle?
    #   @return [true, false] whether this user is idle.
    # @!method online?
    #   @return [true, false] whether this user is online.
    # @!method dnd?
    #   @return [true, false] whether this user is set to do not disturb.
    %i[offline idle online dnd].each do |e|
      define_method("#{e}?") do
        @status.to_sym == e
      end
    end

    # @return [String, nil] the game the user is currently playing, or `nil` if nothing is being played.
    # @deprecated Please use {ActivitySet#games} for information about the user's game activity
    def game
      @activities.games.first&.name
    end

    # @return [Integer] returns 1 for twitch streams, or 0 for no stream.
    # @deprecated Please use {ActivitySet#streaming} for information about the user's stream activity
    def stream_type
      @activities.streaming ? 1 : 0
    end

    # @return [String, nil] the URL to the stream, if the user is currently streaming something
    # @deprecated Please use {ActivitySet#streaming} for information about the user's stream activity
    def stream_url
      @activities.streaming.first&.url
    end

    # The inspect method is overwritten to give more useful output
    def inspect
      "<User username=#{@username} id=#{@id} discriminator=#{@discriminator}>"
    end
  end
end
