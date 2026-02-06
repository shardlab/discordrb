# frozen_string_literal: true

module Discordrb
  # A channel referenced by an invite. It has less data than regular channels, so it's a separate class
  class InviteChannel
    include IDObject

    # @return [String] this channel's name.
    attr_reader :name

    # @return [Integer] this channel's type (0: text, 1: private, 2: voice, 3: group).
    attr_reader :type

    # @!visibility private
    def initialize(data, bot)
      @bot = bot

      @id = data['id'].to_i
      @name = data['name']
      @type = data['type']
    end
  end

  # A server referenced to by an invite
  class InviteServer
    include IDObject
    include ServerAttributes

    # @return [String, nil] the hash of the server's invite splash screen or `nil`.
    attr_reader :splash_id
    alias_method :splash_hash, :splash_id

    # @return [String, nil] the hash of the server's banner, or `nil`.
    attr_reader :banner_id

    # @return [String, nil] the description of this server that's shown on the invite.
    attr_reader :description

    # @return [Array<Symbol>] the features of this server, e.g. `:banner` or `:verified`.
    attr_reader :features

    # @return [String, nil] the code of the server's custom vanity invite link, or `nil`.
    attr_reader :vanity_invite_code

    # @return [Integer] the server's amount of Nitro boosters, 0 if no one has boosted.
    attr_reader :booster_count

    # @return [Integer] the server's Nitro boost level, 0 if no level.
    attr_reader :boost_level

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      @name = data['name']
      @splash_id = data['splash']
      @banner_id = data['banner']
      @description = data['description']
      @icon_id = data['icon']
      @features = data['features']&.map { |feature| feature.downcase.to_sym } || []
      @verification_level = data['verification_level']
      @vanity_invite_code = data['vanity_url_code']
      @nsfw_level = data['nsfw_level']
      @booster_count = data['premium_subscription_count'] || 0
      @boost_level = data['premium_tier'] || 0
    end

    # Utility method to get a server banner URL.
    # @param format [String] the URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @return [String, nil] the URL to the server's banner image, or `nil` if the server doesn't have a banner image.
    def banner_url(format: 'webp')
      API.banner_url(@id, @banner_id, format) if @banner_id
    end

    # Utility method to get a server splash URL.
    # @param format [String] the URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @return [String, nil] the URL to the server's splash image, or `nil` if the server doesn't have a splash image.
    def splash_url(format: 'webp')
      API.splash_url(@id, @splash_id, format) if @splash_id
    end

    # @return [Symbol] the verification level of the server (:none = none, :low = 'Must have a verified email on their Discord account', :medium = 'Has to be registered with Discord for at least 5 minutes', :high = 'Has to be a member of this server for at least 10 minutes', :very_high = 'Must have a verified phone on their Discord account').
    def verification_level
      Discordrb::Server::VERIFICATION_LEVELS.key(@verification_level)
    end
  end

  # A partial role present on an invite.
  class InviteRole
    include IDObject

    # @return [String] the name of the role.
    attr_reader :name

    # @return [Integer] the position of the role.
    attr_reader :position

    # @return [ColourRGB] the primary colour of the role.
    attr_reader :colour
    alias_method :color, :colour

    # @return [String, nil] the hash of the role's custom icon.
    attr_reader :icon

    # @return [String, nil] The unicode emoji of the role, or `nil`.
    attr_reader :unicode_emoji

    # @return [ColourRGB, nil] the secondary colour of the role, or `nil`.
    attr_reader :secondary_colour
    alias_method :secondary_color, :secondary_colour

    # @return [ColourRGB, nil] the tertiary colour of the role, or `nil`.
    attr_reader :tertiary_colour
    alias_method :tertiary_color, :tertiary_colour

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      @name = data['name']
      @icon = data['icon']
      colours = data['colors']
      @position = data['position']
      @unicode_emoji = data['unicode_emoji']
      @colour = ColourRGB.new(colours['primary_color'])
      @tertiary_colour = ColourRGB.new(colours['tertiary_color']) if colours['tertiary_color']
      @secondary_colour = ColourRGB.new(colours['secondary_color']) if colours['secondary_color']
    end

    # Get a string that will mention the role.
    # @return [String] a string that will mention the role, if it is mentionable.
    def mention
      "<@&#{@id}>"
    end

    # Get the URL to the role's custom icon.
    # @param format ['webp', 'png', 'jpeg']
    # @return [String] URL to the icon on Discord's CDN.
    def icon_url(format = 'webp')
      API.role_icon_url(@id, @icon, format) if @icon
    end

    # Get the icon that a role has displayed.
    # @return [String, nil] Icon URL, the unicode emoji, or nil if this role doesn't have any icon.
    # @note A role can have a unicode emoji, and an icon, but only the icon will be shown in the UI.
    def display_icon
      icon_url || unicode_emoji
    end

    # Whether or not the role is of the holographic style.
    # @return [true, false]
    def holographic?
      !@tertiary_colour.nil?
    end

    # Whether or not the role has a two-point gradient.
    # @return [true, false]
    def gradient?
      !@secondary_colour.nil? && @tertiary_colour.nil?
    end
  end

  # A Discord invite to a channel
  class Invite
    # @return [InviteChannel, Channel] the channel this invite references.
    attr_reader :channel

    # @return [InviteServer, Server] the server this invite references.
    attr_reader :server

    # @return [Integer, nil] the amount of times the invite has been used.
    attr_reader :uses
    alias_method :max_uses, :uses

    # @return [User, nil] the user that made this invite. May also be nil if the user can't be determined.
    attr_reader :inviter
    alias_method :user, :inviter
    alias_method :creator, :inviter

    # @return [true, false, nil] whether or not this invite grants temporary membership. If someone joins a server with this invite, they will be removed from the server when they go offline unless they've received a role.
    attr_reader :temporary
    alias_method :temporary?, :temporary

    # @return [String] this invite's code
    attr_reader :code

    # @return [Integer, nil] the amount of members in the server. Will be nil if it has not been resolved.
    attr_reader :member_count
    alias_method :user_count, :member_count

    # @return [Integer, nil] the amount of online members in the server. Will be nil if it has not been resolved.
    attr_reader :online_member_count
    alias_method :online_user_count, :online_member_count

    # @return [Integer, nil] the invites max age before it expires, or nil if it's unknown. If the max age is 0, the invite will never expire unless it's deleted.
    attr_reader :max_age

    # @return [Time, nil] when this invite was created, or nil if it's unknown
    attr_reader :created_at

    # @return [Time, nil] the time at when this invite will expire, or `nil` for never.
    attr_reader :expires_at

    # @return [Integer] the flags for the invite.
    attr_reader :flags

    # @return [Array<Role, InviteRole>] the roles to assign to a user who accepts the invite.
    attr_reader :roles

    # @return [User, nil] the user whose stream will be shown on the invite cover.
    attr_reader :stream_user

    # @return [Application, nil] the embedded application of the invite, or `nil`.
    attr_reader :embedded_application

    # @!visibility private
    def initialize(data, bot, context = false)
      @bot = bot

      @channel = if context
                   bot.channel(data['channel']['id'])
                 elsif data['channel_id']
                   bot.channel(data['channel_id'])
                 else
                   InviteChannel.new(data['channel'], bot)
                 end

      # We need an extra check here because Discord always returns a
      # `guild_id` when fetched via the GET invite endpoint.
      @server = if context
                  bot.server(data['guild']['id'])
                elsif data['guild_id'] && !data['guild']
                  bot.server(data['guild_id'])
                else
                  bot.servers[data['guild']['id'].to_i] || InviteServer.new(data['guild'], bot)
                end

      @uses = data['uses']
      @inviter = data['inviter'] ? bot.ensure_user(data['inviter']) : nil
      @temporary = data['temporary']
      @online_member_count = data['approximate_presence_count']
      @member_count = data['approximate_member_count']
      @max_age = data['max_age']
      @created_at = Time.parse(data['created_at']) if data['created_at']
      @expires_at = Time.parse(data['expires_at']) if data['expires_at']

      @code = data['code']
      @flags = data['flags'] || 0
      @stream_user = bot.ensure_user(data['target_user']) if data['target_user']
      @embedded_application = Application.new(data['target_application'], @bot) if data['target_application']
      role_ids = data['role_ids']&.filter_map { |id| @server.role(id.to_i) }
      @roles = role_ids || (data['roles'] || []).map do |role|
        @server.is_a?(Discordrb::Server) ? @server.role(role['id'].to_i) : InviteRole.new(role, @bot)
      end
    end

    # Check if the invite is still valid.
    # @return [true, false] Whether or not the invite is still valid.
    def revoked?
      !@expires_at.nil? && @expires_at <= Time.now
    end

    alias_method :revoked, :revoked?

    # Code based comparison
    def ==(other)
      other.respond_to?(:code) ? (@code == other.code) : (@code == other)
    end

    # Deletes this invite
    # @param reason [String] The reason the invite is being deleted.
    def delete(reason = nil)
      API::Invite.delete(@bot.token, @code, reason)
    end

    alias_method :revoke, :delete

    # Get the IDs of the users who are allowed to use the invite.
    # @return [Array<Integer>] The IDs of the target users for the invite.
    def target_users
      rows = API::Invite.get_target_users(@bot.token, @code)
      rows.body.lines.tap(&:shift).tap { |lines| lines.map!(&:to_i) }
    end

    # Get the state of the worker used to process the target users upload batch.
    # @return [TargetUsersWorker] An object containing information about the worker.
    def target_users_worker
      data = API::Invite.get_target_users_job_status(@bot.token, @code)
      TargetUsersWorker.new(JSON.parse(data), @bot)
    end

    # Set the target users for the invite. This replaces all of the target users.
    # @param users [File, Array<User, Integer, String>, nil] The new target users of the invite.
    def target_users=(users)
      unless users.respond_to?(:read)
        users = StringIO.new("user_id\n#{users.map(&:resolve_id).join("\n")}", 'rb')
        users.define_singleton_method(:path) { 'ids.csv' }
      end

      API::Invite.update_target_users(@bot.token, @code, target_users_file: users)
    end

    # The inspect method is overwritten to give more useful output
    def inspect
      "<Invite code=#{@code} channel=#{@channel} uses=#{@uses} temporary=#{@temporary} created_at=#{@created_at} max_age=#{@max_age} flags=#{@flags}>"
    end

    # Creates an invite URL.
    def url
      "https://discord.gg/#{@code}"
    end
  end
end
