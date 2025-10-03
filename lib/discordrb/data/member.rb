# frozen_string_literal: true

module Discordrb
  # Mixin for the attributes members and private members should have
  module MemberAttributes
    # Map of server member flags
    MEMBER_FLAGS = {
      rejoined: 1 << 0,
      completed_onboarding: 1 << 1,
      bypassed_verification: 1 << 2,
      started_onboarding: 1 << 3,
      guest: 1 << 4,
      started_home_actions: 1 << 5,
      completed_home_actions: 1 << 6,
      automod_quarantined_username: 1 << 7,
      dm_settings_upsell_acknowledged: 1 << 9,
      automod_quarantined_server_tag: 1 << 10
    }.freeze

    # @return [Time] when this member joined the server.
    attr_reader :joined_at

    # @return [Time, nil] when this member boosted this server, `nil` if they haven't.
    attr_reader :boosting_since

    # @return [String, nil] the nickname this member has, or `nil` if it has none.
    attr_reader :nick
    alias_method :nickname, :nick

    # @return [Array<Role>] the roles this member has.
    attr_reader :roles

    # @return [Server] the server this member is on.
    attr_reader :server

    # @return [Time] When the user's timeout will expire.
    attr_reader :communication_disabled_until
    alias_method :timeout, :communication_disabled_until

    # @return [Integer] the flags set on this member.
    attr_reader :flags

    # @return [true, false] whether the member has not yet passed the server's membership screening requirements.
    attr_reader :pending
    alias_method :pending?, :pending

    # @return [String, nil] the ID of this user's current avatar, can be used to generate a server avatar URL.
    # @see #server_avatar_url
    attr_reader :server_avatar_id

    # @return [String, nil] the ID of this user's current server banner, can be used to generate a banner URL.
    # @see #server_banner_url
    attr_reader :server_banner_id

    # @return [AvatarDecoration, nil] the user's current server avatar decoration, or nil for no server avatar decoration.
    attr_reader :server_avatar_decoration

    # Utility method to get a member's server avatar URL.
    # @param format [String, nil] If `nil`, the URL will default to `webp` for static avatars, and will detect if the member has a `gif` avatar. You can otherwise specify one of `webp`, `jpg`, `png`, or `gif` to override this.
    # @return [String, nil] the URL to the avatar image, or nil if the member doesn't have one.
    def server_avatar_url(format = nil)
      API::Server.avatar_url(@server_id, @user.id, @server_avatar_id, format) if @server_avatar_id
    end

    # Utility method to get a member's server banner URL.
    # @param format [String, nil] If `nil`, the URL will default to `webp` for static banners, and will detect if the member has a `gif` banner. You can otherwise specify one of `webp`, `jpg`, `png`, or `gif` to override this.
    # @return [String, nil] the URL to the banner image, or nil if the member doesn't have one.
    def server_banner_url(format = nil)
      API::Server.banner_url(@server_id, @user.id, @server_banner_id, format) if @server_banner_id
    end

    MEMBER_FLAGS.each do |name, value|
      define_method("#{name}?") do
        @flags.anybits?(value)
      end
    end
  end

  # A member is a user on a server. It differs from regular users in that it has roles, voice statuses and things like
  # that.
  class Member < DelegateClass(User)
    # @return [true, false] whether this member is muted server-wide.
    def mute
      voice_state_attribute(:mute)
    end

    # @return [true, false] whether this member is deafened server-wide.
    def deaf
      voice_state_attribute(:deaf)
    end

    # @return [true, false] whether this member has muted themselves.
    def self_mute
      voice_state_attribute(:self_mute)
    end

    # @return [true, false] whether this member has deafened themselves.
    def self_deaf
      voice_state_attribute(:self_deaf)
    end

    # @return [Channel] the voice channel this member is in.
    def voice_channel
      voice_state_attribute(:voice_channel)
    end

    alias_method :muted?, :mute
    alias_method :deafened?, :deaf
    alias_method :self_muted?, :self_mute
    alias_method :self_deafened?, :self_deaf

    include MemberAttributes

    # @!visibility private
    def initialize(data, server, bot)
      @bot = bot

      @user = bot.ensure_user(data['user'])
      super(@user) # Initialize the delegate class

      @server = server
      @server_id = server&.id || data['guild_id'].to_i

      @role_ids = data['roles']&.map(&:to_i) || []

      @nick = data['nick']
      @joined_at = data['joined_at'] ? Time.parse(data['joined_at']) : nil
      @boosting_since = data['premium_since'] ? Time.parse(data['premium_since']) : nil
      timeout_until = data['communication_disabled_until']
      @communication_disabled_until = timeout_until ? Time.parse(timeout_until) : nil
      @permissions = Permissions.new(data['permissions']) if data['permissions']
      @server_avatar_id = data['avatar']
      @server_banner_id = data['banner']
      @flags = data['flags'] || 0
      @pending = data.key?('pending') ? data['pending'] : false
      @server_avatar_decoration = process_avatar_decoration(data['avatar_decoration_data'])
    end

    # @return [Server] the server this member is on.
    # @raise [Discordrb::Errors::NoPermission] This can happen when receiving interactions for servers in which the bot is not
    #   authorized with the `bot` scope.
    def server
      return @server if @server

      @server = @bot.server(@server_id)
      raise Discordrb::Errors::NoPermission, 'The bot does not have access to this server' unless @server

      @server
    end

    # @return [Array<Role>] the roles this member has.
    # @raise [Discordrb::Errors::NoPermission] This can happen when receiving interactions for servers in which the bot is not
    #   authorized with the `bot` scope.
    def roles
      return @roles if @roles

      update_roles(@role_ids)
      @roles
    end

    # @return [true, false] if this user is a Nitro Booster of this server.
    def boosting?
      !@boosting_since.nil?
    end

    # @return [true, false] whether this member is the server owner.
    def owner?
      server.owner == self
    end

    # @param role [Role, String, Integer] the role to check or its ID.
    # @return [true, false] whether this member has the specified role.
    def role?(role)
      role = role.resolve_id
      roles.any?(role)
    end

    # @see Member#set_roles
    def roles=(role)
      set_roles(role)
    end

    # Check if the current user has communication disabled.
    # @return [true, false]
    def communication_disabled?
      !@communication_disabled_until.nil? && @communication_disabled_until > Time.now
    end

    alias_method :timeout?, :communication_disabled?

    # Set a user's timeout duration, or remove it by setting the timeout to `nil`.
    # @param timeout_until [Time, nil] When the timeout will end.
    def communication_disabled_until=(timeout_until)
      raise ArgumentError, 'A time out cannot exceed 28 days' if timeout_until && timeout_until > (Time.now + 2_419_200)

      update_member_data(communication_disabled_until: timeout_until&.iso8601)
    end

    alias_method :timeout=, :communication_disabled_until=

    # Bulk sets a member's roles.
    # @param role [Role, Array<Role>] The role(s) to set.
    # @param reason [String] The reason the user's roles are being changed.
    def set_roles(role, reason = nil)
      role_ids = role_id_array(role)
      update_member_data(roles: role_ids, reason: reason)
    end

    # Adds and removes roles from a member.
    # @param add [Role, Array<Role>] The role(s) to add.
    # @param remove [Role, Array<Role>] The role(s) to remove.
    # @param reason [String] The reason the user's roles are being changed.
    # @example Remove the 'Member' role from a user, and add the 'Muted' role to them.
    #   to_add = server.roles.find {|role| role.name == 'Muted'}
    #   to_remove = server.roles.find {|role| role.name == 'Member'}
    #   member.modify_roles(to_add, to_remove)
    def modify_roles(add, remove, reason = nil)
      add_role_ids = role_id_array(add)
      remove_role_ids = role_id_array(remove)
      old_role_ids = resolve_role_ids
      new_role_ids = (old_role_ids - remove_role_ids + add_role_ids).uniq

      update_member_data(roles: new_role_ids, reason: reason)
    end

    # Adds one or more roles to this member.
    # @param role [Role, Array<Role, String, Integer>, String, Integer] The role(s), or their ID(s), to add.
    # @param reason [String] The reason the user's roles are being changed.
    def add_role(role, reason = nil)
      role_ids = role_id_array(role)

      if role_ids.count.one?
        API::Server.add_member_role(@bot.token, @server_id, @user.id, role_ids[0], reason)
      else
        old_role_ids = resolve_role_ids
        new_role_ids = (old_role_ids + role_ids).uniq
        update_member_data(roles: new_role_ids, reason: reason)
      end
    end

    # Removes one or more roles from this member.
    # @param role [Role, Array<Role>] The role(s) to remove.
    # @param reason [String] The reason the user's roles are being changed.
    def remove_role(role, reason = nil)
      role_ids = role_id_array(role)

      if role_ids.count.one?
        API::Server.remove_member_role(@bot.token, @server_id, @user.id, role_ids[0], reason)
      else
        old_role_ids = resolve_role_ids
        new_role_ids = old_role_ids.reject { |i| role_ids.include?(i) }
        update_member_data(roles: new_role_ids, reason: reason)
      end
    end

    # @return [Role] the highest role this member has.
    def highest_role
      roles.max_by(&:position)
    end

    # @return [Role, nil] the role this member is being hoisted with.
    def hoist_role
      hoisted_roles = roles.select(&:hoist)
      return nil if hoisted_roles.empty?

      hoisted_roles.max_by(&:position)
    end

    # @return [Role, nil] the role this member is basing their colour on.
    def colour_role
      coloured_roles = roles.select { |v| v.colour.combined.nonzero? }
      return nil if coloured_roles.empty?

      coloured_roles.max_by(&:position)
    end

    alias_method :color_role, :colour_role

    # @return [ColourRGB, nil] the colour this member has.
    def colour
      return nil unless colour_role

      colour_role.color
    end

    alias_method :color, :colour

    # Server deafens this member.
    # @param reason [String, nil] The reason for defeaning this member.
    def server_deafen(reason: nil)
      update_member_data(deaf: true, reason: reason)
    end

    # Server undeafens this member.
    # @param reason [String, nil] The reason for un-defeaning this member.
    def server_undeafen(reason: nil)
      update_member_data(deaf: false, reason: reason)
    end

    # Server mutes this member.
    # @param reason [String, nil] The reason for muting this member.
    def server_mute(reason: nil)
      update_member_data(mute: true, reason: reason)
    end

    # Server unmutes this member.
    # @param reason [String, nil] The reason for un-muting this member.
    def server_unmute(reason: nil)
      update_member_data(mute: false, reason: reason)
    end

    # Bans this member from the server.
    # @param message_days [Integer] How many days worth of messages sent by the member should be deleted. This parameter is deprecated and will be removed in 4.0.
    # @param message_seconds [Integer] How many seconds worth of messages sent by the member should be deleted.
    # @param reason [String] The reason this member is being banned.
    def ban(message_days = 0, message_seconds: nil, reason: nil)
      server.ban(@user, message_days, message_seconds: message_seconds, reason: reason)
    end

    # Unbans this member from the server.
    # @param reason [String] The reason this member is being unbanned.
    def unban(reason = nil)
      server.unban(@user, reason)
    end

    # Kicks this member from the server.
    # @param reason [String] The reason this member is being kicked.
    def kick(reason = nil)
      server.kick(@user, reason)
    end

    # @see Member#set_nick
    def nick=(nick)
      set_nick(nick)
    end

    alias_method :nickname=, :nick=

    # Sets or resets this member's nickname. Requires the Change Nickname permission for the bot itself and Manage
    # Nicknames for other users.
    # @param nick [String, nil] The string to set the nickname to, or nil if it should be reset.
    # @param reason [String] The reason the user's nickname is being changed.
    def set_nick(nick, reason = nil)
      if @user.current_bot?
        update_current_member_data(nick: nick, reason: reason)
      else
        update_member_data(nick: nick, reason: reason)
      end
    end

    alias_method :set_nickname, :set_nick

    # @return [String] the name the user displays as (nickname if they have one, global_name if they have one, username otherwise)
    def display_name
      nickname || global_name || username
    end

    # @param format [String, nil] If `nil`, the URL will default to `webp` for static avatars, and will detect if the member has a `gif` avatar. You can otherwise specify one of `webp`, `jpg`, `png`, or `gif` to override this.
    # @return [String, nil] the avatar that the user has displayed (server avatar if they have one, user avatar if they have one, nil otherwise)
    def display_avatar_url(format = nil)
      server_avatar_url(format) || avatar_url(format)
    end

    # @param format [String, nil] If `nil`, the URL will default to `webp` for static banners, and will detect if the member has a `gif` banner. You can otherwise specify one of `webp`, `jpg`, `png`, or `gif` to override this.
    # @return [String, nil] the banner that the user has displayed (server banner if they have one, user banner if they have one, nil otherwise)
    def display_banner_url(format = nil)
      server_banner_url(format) || banner_url(format)
    end

    # @return [AvatarDecoration, nil] the avatar decoration that the user displays (server avatar decoration if they have one, user avatar decoration if they have one, nil otherwise)
    def display_avatar_decoration
      server_avatar_decoration || avatar_decoration
    end

    # Set the flags for this member.
    # @param flags [Integer, nil] The new bitwise value of flags for this member, or nil.
    def flags=(flags)
      update_member_data(flags: flags)
    end

    # Set the server banner for the current bot.
    # @param banner [File, nil] A file like object that responds to read, or `nil`.
    def server_banner=(banner)
      raise 'Can only set a banner for the current bot' unless current_bot?

      banner = banner.respond_to?(:read) ? Discordrb.encode64(banner) : banner

      update_data(JSON.parse(API::Server.update_current_member(@bot.token, @server_id, :undef, nil, banner)))
    end

    # Set the server avatar for the current bot.
    # @param avatar [File, nil] A file like object that responds to read, or `nil`.
    def server_avatar=(avatar)
      raise 'Can only set an avatar for the current bot' unless current_bot?

      avatar = avatar.respond_to?(:read) ? Discordrb.encode64(avatar) : avatar

      update_data(JSON.parse(API::Server.update_current_member(@bot.token, @server_id, :undef, nil, :undef, avatar)))
    end

    # Set the server bio for the current bot.
    # @param bio [String, nil] The new server bio for the bot, or nil.
    def server_bio=(bio)
      raise 'Can only set a bio for the current bot' unless current_bot?

      update_data(JSON.parse(API::Server.update_current_member(@bot.token, @server_id, :undef, nil, :undef, :undef, bio)))
    end

    # Update this member's roles
    # @note For internal use only.
    # @!visibility private
    def update_roles(role_ids)
      @roles = [server.role(@server_id)]
      role_ids.each do |id|
        # It is possible for members to have roles that do not exist
        # on the server any longer. See https://github.com/discordrb/discordrb/issues/371
        role = server.role(id)
        @roles << role if role
      end
    end

    # Update this member's nick
    # @note For internal use only.
    # @!visibility private
    def update_nick(nick)
      @nick = nick
    end

    # Update this member's boosting timestamp
    # @note For internal user only.
    # @!visibility private
    def update_boosting_since(time)
      @boosting_since = time
    end

    # @!visibility private
    def update_communication_disabled_until(time)
      time = time ? Time.parse(time) : nil
      @communication_disabled_until = time
    end

    # Update this member
    # @note For internal use only.
    # @!visibility private
    def update_data(data)
      update_roles(data['roles']) if data['roles']
      @nick = data['nick'] if data.key?('nick')
      @mute = data['mute'] if data.key?('mute')
      @deaf = data['deaf'] if data.key?('deaf')
      @server_avatar_id = data['avatar'] if data.key?('avatar')
      @server_banner_id = data['banner'] if data.key?('banner')
      @flags = data['flags'] if data.key?('flags')
      @pending = data['pending'] if data.key?('pending')

      @joined_at = Time.parse(data['joined_at']) if data['joined_at']

      if data.key?('communication_disabled_until')
        timeout_until = data['communication_disabled_until']
        @communication_disabled_until = timeout_until ? Time.parse(timeout_until) : nil
      end

      if data.key('premium_since')
        @boosting_since = data['premium_since'] ? Time.parse(data['premium_since']) : nil
      end

      if (user = data['user'])
        @user.update_global_name(user['global_name']) if user['global_name']
        @user.avatar_id = user['avatar'] if user.key('avatar')
        @user.update_avatar_decoration(user['avatar_decoration_data']) if user.key?('avatar_decoration_data')
        @user.update_collectibles(user['collectibles']) if user.key?('collectibles')
        @user.update_primary_server(user['primary_guild']) if user.key?('primary_guild')
      end

      @server_avatar_decoration = process_avatar_decoration(data['avatar_decoration_data']) if data.key?('avatar_decoration_data')
    end

    include PermissionCalculator

    # Overwriting inspect for debug purposes
    def inspect
      "<Member user=#{@user.inspect} server=#{@server&.inspect || @server_id} joined_at=#{@joined_at} roles=#{@roles&.inspect || @role_ids} voice_channel=#{voice_channel.inspect} mute=#{mute} deaf=#{deaf} self_mute=#{self_mute} self_deaf=#{self_deaf}>"
    end

    private

    # Utility method to get a list of role IDs from one role or an array of roles
    def role_id_array(role)
      if role.is_a? Array
        role.map(&:resolve_id)
      else
        [role.resolve_id]
      end
    end

    # Utility method to get data out of this member's voice state
    def voice_state_attribute(name)
      voice_state = server.voice_states[@user.id]
      voice_state&.send name
    end

    # @!visibility private
    def resolve_role_ids
      @roles ? @roles.collect(&:id) : @role_ids
    end

    # @!visibility private
    def update_member_data(new_data)
      update_data(JSON.parse(API::Server.update_member(@bot.token, @server_id, @user.id, **new_data)))
    end

    # @!visibility private
    def update_current_member_data(new_data)
      update_data(JSON.parse(API::Server.update_current_member(@bot.token, @server_id,
                                                               new_data.key?(:nick) ? new_data[:nick] : :undef,
                                                               new_data[:reason])))
    end
  end
end
