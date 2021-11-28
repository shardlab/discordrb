# frozen_string_literal: true

module Discordrb
  # Basic attributes a guild should have
  module GuildAttributes
    # @return [String] this guild's name.
    attr_reader :name

    # @return [String] the hexadecimal ID used to identify this guild's icon.
    attr_reader :icon_id

    # Utility function to get the URL for the icon image
    # @return [String] the URL to the icon image
    def icon_url
      return nil unless @icon_id

      API.icon_url(@id, @icon_id)
    end
  end

  # A guild on Discord
  class Guild
    include IDObject
    include GuildAttributes

    # @return [String] the ID of the region the guild is on (e.g. `amsterdam`).
    attr_reader :region_id

    # @return [Array<Channel>] an array of all the channels (text and voice) on this guild.
    attr_reader :channels

    # @return [Array<Role>] an array of all the roles created on this guild.
    attr_reader :roles

    # @return [Hash<Integer => Emoji>] a hash of all the emoji available on this guild.
    attr_reader :emoji
    alias_method :emojis, :emoji

    # @return [true, false] whether or not this guild is large (members > 100). If it is,
    # it means the members list may be inaccurate for a couple seconds after starting up the bot.
    attr_reader :large
    alias_method :large?, :large

    # @return [Array<Symbol>] the features of the guild (eg. "INVITE_SPLASH")
    attr_reader :features

    # @return [Integer] the absolute number of members on this guild, offline or not.
    attr_reader :member_count

    # @return [Integer] the amount of time after which a voice user gets moved into the AFK channel, in seconds.
    attr_reader :afk_timeout

    # @return [Hash<Integer => VoiceState>] the hash (user ID => voice state) of voice states of members on this guild
    attr_reader :voice_states

    # The guild's amount of Nitro boosters.
    # @return [Integer] the amount of boosters, 0 if no one has boosted.
    attr_reader :booster_count

    # The guild's Nitro boost level.
    # @return [Integer] the boost level, 0 if no level.
    attr_reader :boost_level

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @owner_id = data[:owner_id].to_i
      @id = data[:id].to_i
      @members = {}
      @voice_states = {}
      @emoji = {}

      process_channels(data[:channels])
      update_data(data)

      # Whether this guild's members have been chunked (resolved using op 8 and GUILD_MEMBERS_CHUNK) yet
      @chunked = false

      @booster_count = data[:premium_subscription_count] || 0
      @boost_level = data[:premium_tier]
    end

    # @return [Member] The guild owner.
    def owner
      @owner ||= member(@owner_id)
    end

    # The default channel is the text channel on this guild with the highest position
    # that the bot has Read Messages permission on.
    # @param send_messages [true, false] whether to additionally consider if the bot has Send Messages permission
    # @return [Channel, nil] The default channel on this guild, or `nil` if there are no channels that the bot can read.
    def default_channel(send_messages = false)
      bot_member = member(@bot.profile)
      text_channels.sort_by { |e| [e.position, e.id] }.find do |e|
        if send_messages
          bot_member.can_read_messages?(e) && bot_member.can_send_messages?(e)
        else
          bot_member.can_read_messages?(e)
        end
      end
    end

    alias_method :general_channel, :default_channel

    # @return [Role] The @everyone role on this guild
    def everyone_role
      role(@id)
    end

    # Gets a role on this guild based on its ID.
    # @param id [String, Integer] The role ID to look for.
    # @return [Role, nil] The role identified by the ID, or `nil` if it couldn't be found.
    def role(id)
      id = id.resolve_id
      @roles.find { |e| e.id == id }
    end

    # Gets a member on this guild based on user ID
    # @param id [Integer] The user ID to look for
    # @param request [true, false] Whether the member should be requested from Discord if it's not cached
    def member(id, request = true)
      id = id.resolve_id
      return @members[id] if member_cached?(id)
      return nil unless request

      member = @bot.member(self, id)
      @members[id] = member unless member.nil?
    rescue StandardError
      nil
    end

    # @return [Array<Member>] an array of all the members on this guild.
    # @raise [RuntimeError] if the bot was not started with the :guild_member intent
    def members
      return @members.values if @chunked

      @bot.debug("Members for guild #{@id} not chunked yet - initiating")

      # If the GUILD_MEMBERS intent flag isn't set, the gateway won't respond when we ask for members.
      raise 'The :guild_members intent is required to get guild members' if (@bot.gateway.intents & INTENTS[:guild_members]).zero?

      @bot.request_chunks(@id)
      sleep 0.05 until @chunked
      @members.values
    end

    alias_method :users, :members

    # @return [Array<Member>] an array of all the bot members on this guild.
    def bot_members
      members.select(&:bot_account?)
    end

    # @return [Array<Member>] an array of all the non bot members on this guild.
    def non_bot_members
      members.reject(&:bot_account?)
    end

    # @return [Member] the bot's own `Member` on this guild
    def bot
      member(@bot.profile)
    end

    # @return [Array<Integration>] an array of all the integrations connected to this guild.
    def integrations
      integration = @bot.client.get_guild_integrations(@id)
      integration.map { |element| Integration.new(element, @bot, self) }
    end

    # @param action [Symbol] The action to only include.
    # @param user [User, String, Integer] The user, or their ID, to filter entries to.
    # @param limit [Integer] The amount of entries to limit it to.
    # @param before [Entry, String, Integer] The entry, or its ID, to use to not include all entries after it.
    # @return [AuditLogs] The guild's audit logs.
    def audit_logs(action: nil, user: nil, limit: 50, before: nil)
      raise 'Invalid audit log action!' if action && AuditLogs::ACTIONS.key(action).nil?

      action = AuditLogs::ACTIONS.key(action)
      user = user.resolve_id if user
      before = before.resolve_id if before
      params = { action_type: action, before: before, user_id: user, limit: limit }.compact
      resp = @bot.client.get_guild_audit_log(@id, **params)

      AuditLogs.new(self, @bot, resp)
    end

    # Cache @widget
    # @note For internal use only
    # @!visibility private
    def cache_widget_data
      data = @bot.client.get_guild_widget(@id)
      @widget_enabled = data[:enabled]
      @widget_channel_id = data[:channel_id]
    end

    # @return [true, false] whether or not the guild has widget enabled
    def widget_enabled?
      cache_widget_data if @widget_enabled.nil?
      @widget_enabled
    end
    alias_method :widget?, :widget_enabled?
    alias_method :embed_enabled, :widget_enabled?
    alias_method :embed?, :widget_enabled?

    # @return [Channel, nil] the channel the guild widget will make an invite for.
    def widget_channel
      cache_widget_data if @widget_enabled.nil?
      @bot.channel(@widget_channel_id) if @widget_channel_id
    end
    alias_method :embed_channel, :widget_channel

    # Sets whether this guild's widget is enabled
    # @param value [true, false]
    def widget_enabled=(value)
      modify_widget(value, widget_channel)
    end
    alias_method :embed_enabled=, :widget_enabled=

    # Sets whether this guild's widget is enabled
    # @param value [true, false]
    # @param reason [String, nil] the reason to be shown in the audit log for this action
    def set_widget_enabled(value, reason = nil)
      modify_widget(value, widget_channel, reason)
    end
    alias_method :set_embed_enabled, :set_widget_enabled

    # Changes the channel on the guild's widget
    # @param channel [Channel, String, Integer] the channel, or its ID, to be referenced by the widget
    def widget_channel=(channel)
      modify_widget(widget?, channel)
    end
    alias_method :embed_channel=, :widget_channel=

    # Changes the channel on the guild's widget
    # @param channel [Channel, String, Integer] the channel, or its ID, to be referenced by the widget
    # @param reason [String, nil] the reason to be shown in the audit log for this action
    def set_widget_channel(channel, reason = nil)
      modify_widget(widget?, channel, reason)
    end
    alias_method :set_embed_channel, :set_widget_channel

    # Changes the channel on the guild's widget, and sets whether it is enabled.
    # @param enabled [true, false] whether the widget is enabled
    # @param channel [Channel, String, Integer] the channel, or its ID, to be referenced by the widget
    # @param reason [String, nil] the reason to be shown in the audit log for this action
    def modify_widget(enabled, channel, reason = nil)
      cache_widget_data if @widget_enabled.nil?
      channel_id = channel ? channel.resolve_id : @widget_channel_id
      resp = @bot.client.modify_guild_widget(@id, enabled: enabled, channel_id: channel_id, reason: reason)
      @widget_enabled = resp[:enabled]
      @widget_channel_id = resp[:channel_id]
    end
    alias_method :modify_embed, :modify_widget

    # @param include_idle [true, false] Whether to count idle members as online.
    # @param include_bots [true, false] Whether to include bot accounts in the count.
    # @return [Array<Member>] an array of online members on this guild.
    def online_members(include_idle: false, include_bots: true)
      @members.values.select do |e|
        ((include_idle ? e.idle? : false) || e.online?) && (include_bots ? true : !e.bot_account?)
      end
    end

    alias_method :online_users, :online_members

    # Adds a member to this guild that has granted this bot's application an OAuth2 access token
    # with the `guilds.join` scope.
    # For more information about Discord's OAuth2 implementation, see: https://discord.com/developers/docs/topics/oauth2
    # @note Your bot must be present in this guild, and have permission to create instant invites for this to work.
    # @param user [User, String, Integer] the user, or ID of the user to add to this guild
    # @param access_token [String] the OAuth2 Bearer token that has been granted the `guilds.join` scope
    # @param nick [String] the nickname to give this member upon joining
    # @param roles [Role, Array<Role, String, Integer>] the role (or roles) to give this member upon joining
    # @param deaf [true, false] whether this member will be guild deafened upon joining
    # @param mute [true, false] whether this member will be guild muted upon joining
    # @return [Member, nil] the created member, or `nil` if the user is already a member of this guild.
    def add_member_using_token(user, access_token, nick: nil, roles: [], deaf: false, mute: false)
      user_id = user.resolve_id
      roles = roles.is_a?(Array) ? roles.map(&:resolve_id) : [roles.resolve_id]
      params = { access_token: access_token, nick: nick, roles: roles, deaf: deaf, mute: mute }.compact

      resp = @bot.client.add_guild_member(@id, user_id, **params)
      return nil if resp.empty?

      add_member Member.new(resp, self, @bot)
    end

    # Returns the amount of members that are candidates for pruning
    # @param days [Integer] the number of days to consider for inactivity
    # @return [Integer] number of members to be removed
    # @raise [ArgumentError] if days is not between 1 and 30 (inclusive)
    def prune_count(days)
      raise ArgumentError, 'Days must be between 1 and 30' unless days.between?(1, 30)

      resp = @bot.client.get_guild_prune_count(@id, days: days)
      resp[:pruned]
    end

    # Prunes (kicks) an amount of members for inactivity
    # @param days [Integer] the number of days to consider for inactivity (between 1 and 30)
    # @param reason [String] The reason the for the prune.
    # @return [Integer] the number of members removed at the end of the operation
    # @raise [ArgumentError] if days is not between 1 and 30 (inclusive)
    def begin_prune(days, reason = nil)
      raise ArgumentError, 'Days must be between 1 and 30' unless days.between?(1, 30)

      resp = @bot.client.begin_guild_prune(@id, days: days, reason: reason)
      resp[:pruned]
    end

    alias_method :prune, :begin_prune

    # @return [Array<Channel>] an array of text channels on this guild
    def text_channels
      @channels.select(&:text?)
    end

    # @return [Array<Channel>] an array of voice channels on this guild
    def voice_channels
      @channels.select(&:voice?)
    end

    # @return [Array<Channel>] an array of category channels on this guild
    def categories
      @channels.select(&:category?)
    end

    # @return [Array<Channel>] an array of channels on this guild that are not in a category
    def orphan_channels
      @channels.reject { |c| c.parent || c.category? }
    end

    # @return [String, nil] the widget URL to the guild that displays the amount of online members in a
    #   stylish way. `nil` if the widget is not enabled.
    def widget_url
      update_data if @embed_enabled.nil?
      return unless @embed_enabled

      API.widget_url(@id)
    end

    # @param style [Symbol] The style the picture should have. Possible styles are:
    #   * `:banner1` creates a rectangular image with the guild name, member count and icon, a "Powered by Discord" message on the bottom and an arrow on the right.
    #   * `:banner2` creates a less tall rectangular image that has the same information as `banner1`, but the Discord logo on the right - together with the arrow and separated by a diagonal separator.
    #   * `:banner3` creates an image similar in size to `banner1`, but it has the arrow in the bottom part, next to the Discord logo and with a "Chat now" text.
    #   * `:banner4` creates a tall, almost square, image that prominently features the Discord logo at the top and has a "Join my guild" in a pill-style button on the bottom. The information about the guild is in the same format as the other three `banner` styles.
    #   * `:shield` creates a very small, long rectangle, of the style you'd find at the top of GitHub `README.md` files. It features a small version of the Discord logo at the left and the member count at the right.
    # @return [String, nil] the widget banner URL to the guild that displays the amount of online members,
    #   guild icon and guild name in a stylish way. `nil` if the widget is not enabled.
    def widget_banner_url(style)
      update_data if @embed_enabled.nil?
      return unless @embed_enabled

      API.widget_url(@id, style)
    end

    # @return [String] the hexadecimal ID used to identify this guild's splash image for their VIP invite page.
    def splash_id
      @splash_id ||= @bot.client.get_guild(@id)[:splash]
    end
    alias splash_hash splash_id

    # @return [String, nil] the splash image URL for the guild's VIP invite page.
    #   `nil` if there is no splash image.
    def splash_url
      splash_id if @splash_id.nil?
      return nil unless @splash_id

      API.splash_url(@id, @splash_id)
    end

    # @return [String] the hexadecimal ID used to identify this guild's banner image, shown by the guild name.
    def banner_id
      @banner_id ||= @bot.client.get_guild(@id)[:banner]
    end

    # @return [String, nil] the banner image URL for the guild's banner image, or
    #   `nil` if there is no banner image.
    def banner_url
      banner_id if @banner_id.nil?
      return unless banner_id

      Discordrb.banner_url(@id, @banner_id)
    end

    # @return [String] a URL that a user can use to navigate to this guild in the client
    def link
      "https://discord.com/channels/#{@id}"
    end

    alias_method :jump_link, :link

    # Adds a role to the role cache
    # @note For internal use only
    # @!visibility private
    def add_role(role)
      @roles << role
    end

    # Removes a role from the role cache
    # @note For internal use only
    # @!visibility private
    def delete_role(role_id)
      @roles.reject! { |r| r.id == role_id }
      @members.each do |_, member|
        new_roles = member.roles.reject { |r| r.id == role_id }
        member.update_roles(new_roles)
      end
      @channels.each do |channel|
        overwrites = channel.permission_overwrites.reject { |id, _| id == role_id }
        channel.update_overwrites(overwrites)
      end
    end

    # Updates the positions of all roles on the guild
    # @note For internal use only
    # @!visibility private
    def update_role_positions(role_positions)
      response = @bot.client.modify_guild_role_positions(@id, role_positions)
      response.each do |data|
        updated_role = Role.new(data, @bot, self)
        role(updated_role.id).update_from(updated_role)
      end
    end

    # Adds a member to the member cache.
    # @note For internal use only
    # @!visibility private
    def add_member(member)
      @member_count += 1
      @members[member.id] = member
    end

    # Removes a member from the member cache.
    # @note For internal use only
    # @!visibility private
    def delete_member(user_id)
      @members.delete(user_id)
      @member_count -= 1 unless @member_count <= 0
    end

    # Checks whether a member is cached
    # @note For internal use only
    # @!visibility private
    def member_cached?(user_id)
      @members.include?(user_id)
    end

    # Adds a member to the cache
    # @note For internal use only
    # @!visibility private
    def cache_member(member)
      @members[member.id] = member
    end

    # Updates a member's voice state
    # @note For internal use only
    # @!visibility private
    def update_voice_state(data)
      user_id = data[:user_id].to_i

      if data[:channel_id]
        unless @voice_states[user_id]
          # Create a new voice state for the user
          @voice_states[user_id] = VoiceState.new(user_id)
        end

        # Update the existing voice state (or the one we just created)
        channel = @channels_by_id[data[:channel_id].to_i]
        @voice_states[user_id].update(
          channel,
          data[:mute],
          data[:deaf],
          data[:self_mute],
          data[:self_deaf]
        )
      else
        # The user is not in a voice channel anymore, so delete its voice state
        @voice_states.delete(user_id)
      end
    end

    # Creates a channel on this guild with the given name.
    # @note If parent is provided, permission overwrites have the follow behavior:
    #
    #  1. If overwrites is null, the new channel inherits the parent's permissions.
    #  2. If overwrites is [], the new channel inherits the parent's permissions.
    #  3. If you supply one or more overwrites, the channel will be created with those permissions and ignore the parents.
    #
    # @param name [String] Name of the channel to create
    # @param type [Integer, Symbol] Type of channel to create (0: text, 2: voice, 4: category, 5: news, 6: store)
    # @param topic [String] the topic of this channel, if it will be a text channel
    # @param bitrate [Integer] the bitrate of this channel, if it will be a voice channel
    # @param user_limit [Integer] the user limit of this channel, if it will be a voice channel
    # @param permission_overwrites [Array<Hash>, Array<Overwrite>] permission overwrites for this channel
    # @param parent [Channel, String, Integer] parent category, or its ID, for this channel to be created in.
    # @param nsfw [true, false] whether this channel should be created as nsfw
    # @param rate_limit_per_user [Integer] how many seconds users need to wait in between messages.
    # @param reason [String] The reason the for the creation of this channel.
    # @return [Channel] the created channel.
    # @raise [ArgumentError] if type is not 0 (text), 2 (voice), 4 (category), 5 (news), or 6 (store)
    def create_channel(name, type = 0, topic: nil, bitrate: nil, user_limit: nil, permission_overwrites: nil, parent: nil, nsfw: false, rate_limit_per_user: nil, position: nil, reason: nil)
      type = Channel::TYPES[type] if type.is_a?(Symbol)
      raise ArgumentError, 'Channel type must be either 0 (text), 2 (voice), 4 (category), news (5), or store (6)!' unless [0, 2, 4, 5, 6].include?(type)

      permission_overwrites.map! { |e| e.is_a?(Overwrite) ? e.to_hash : e } if permission_overwrites.is_a?(Array)
      parent_id = parent.respond_to?(:resolve_id) ? parent.resolve_id : nil
      params = {
        name: name, type: type, topic: topic, bitrate: bitrate, user_limit: user_limit,
        permission_overwrites: permission_overwrites, parent_id: parent_id, nsfw: nsfw,
        rate_limit_per_user: rate_limit_per_user, position: position
      }.compact

      resp = @bot.client.create_guild_channel(@id, **params, reason: reason)
      Channel.new(resp, @bot)
    end

    # Creates a role on this guild which can then be modified. It will be initialized
    # with the regular role defaults the client uses unless specified, i.e. name is "new role",
    # permissions are the default, colour is the default etc.
    # @param name [String] Name of the role to create
    # @param colour [Integer, ColourRGB, #combined] The roles colour
    # @param hoist [true, false]
    # @param mentionable [true, false]
    # @param permissions [Integer, Array<Symbol>, Permissions, #bits] The permissions to write to the new role.
    # @param reason [String] The reason the for the creation of this role.
    # @return [Role] the created role.
    def create_role(name: 'new role', colour: 0, hoist: false, mentionable: false, permissions: 104_324_161, reason: nil)
      colour = colour.respond_to?(:combined) ? colour.combined : colour

      permissions = if permissions.is_a?(Array)
                      Permissions.bits(permissions)
                    elsif permissions.respond_to?(:bits)
                      permissions.bits
                    else
                      permissions
                    end

      params = {
        name: name, color: colour, hoist: hoist, mentionable: mentionable, permissions: permissions
      }.compact

      resp = @bot.client.create_guild_role(@id, **params, reason: reason)
      role = Role.new(resp, @bot, self)
      @roles << role
      role
    end

    # Adds a new custom emoji on this guild.
    # @param name [String] The name of emoji to create.
    # @param image [String, #read] A base64 encoded string with the image data, or an object that responds to `#read`, such as `File`.
    # @param roles [Array<Role, String, Integer>] An array of roles, or role IDs to be whitelisted for this emoji.
    # @param reason [String] The reason the for the creation of this emoji.
    # @return [Emoji] The emoji that has been added.
    def add_emoji(name, image, roles = [], reason: nil)
      image_string = image
      if image.respond_to? :read
        image_string = 'data:image/jpg;base64,'
        image_string += Base64.strict_encode64(image.read)
      end
      params = { name: name, image: image_string, roles: roles.map(&:resolve_id) }.compact

      data = @bot.client.create_guild_emoji(@id, **params, reason: reason)
      new_emoji = Emoji.new(data, @bot, self)
      @emoji[new_emoji.id] = new_emoji
    end

    # Delete a custom emoji on this guild
    # @param emoji [Emoji, String, Integer] The emoji or emoji ID to be deleted.
    # @param reason [String] The reason the for the deletion of this emoji.
    def delete_emoji(emoji, reason: nil)
      @bot.client.delete_guild_emoji(@id, emoji.resolve_id, reason: reason)
    end

    # Changes the name and/or role whitelist of an emoji on this guild.
    # @param emoji [Emoji, String, Integer] The emoji or emoji ID to edit.
    # @param name [String] The new name for the emoji.
    # @param roles [Array<Role, String, Integer>] A new array of roles, or role IDs, to whitelist.
    # @param reason [String] The reason for the editing of this emoji.
    # @return [Emoji] The edited emoji.
    def edit_emoji(emoji, name: nil, roles: nil, reason: nil)
      emoji = @emoji[emoji.resolve_id]
      params = {
        name: name, roles: roles&.map(&:resolve_id)
      }

      data = @bot.client.edit_emoji(@id, emoji.resolve_id, **params, reason: reason)
      new_emoji = Emoji.new(data, @bot, self)
      @emoji[new_emoji.id] = new_emoji
    end

    # The amount of emoji the guild can have, based on its current Nitro Boost Level.
    # @return [Integer] the max amount of emoji
    def max_emoji
      case @level
      when 1
        100
      when 2
        150
      when 3
        250
      else
        50
      end
    end

    # @return [Array<GuildBan>] a list of banned users on this guild and the reason they were banned.
    def bans
      response = @bot.client.get_guild_bans(@id)
      response.map do |e|
        GuildBan.new(self, User.new(e[:user], @bot), e[:reason])
      end
    end

    # Bans a user from this guild.
    # @param user [User, String, Integer] The user to ban.
    # @param message_days [Integer] How many days worth of messages sent by the user should be deleted.
    # @param reason [String] The reason the user is being banned.
    def ban(user, message_days = 0, reason: nil)
      @bot.client.create_guild_ban(@id, user.resolve_id, delete_message_days: message_days, reason: reason)
    end

    # Unbans a previously banned user from this guild.
    # @param user [User, String, Integer] The user to unban.
    # @param reason [String] The reason the user is being unbanned.
    def unban(user, reason = nil)
      @bot.client.remove_guild_ban(@id, user.resolve_id, reason: reason)
    end

    # Kicks a user from this guild.
    # @param user [User, String, Integer] The user to kick.
    # @param reason [String] The reason the user is being kicked.
    def kick(user, reason = nil)
      @bot.client.remove_guild_member(@id, user.resolve_id, reason: reason)
    end

    # Forcibly moves a user into a different voice channel. Only works if the bot has the permission needed.
    # @param user [User, String, Integer] The user to move.
    # @param channel [Channel, String, Integer] The voice channel to move into.
    def move(user, channel)
      @bot.client.modify_guild_member(@id, user.resolve_id, channel_id: channel.resolve_id)
    end

    # Deletes this guild. Be aware that this is permanent and impossible to undo, so be careful!
    def delete
      @bot.client.delete_guild(@id)
    end

    # Leave the guild.
    def leave
      @bot.client.leave_guild(@id)
    end

    # Transfers guild ownership to another user.
    # TODO: Is this supported for bots?
    # @param user [User, String, Integer] The user who should become the new owner.
    def owner=(user)
      API::Guild.transfer_ownership(@bot.token, @id, user.resolve_id)
    end

    # Sets the guild's name.
    # @param name [String] The new guild name.
    def name=(name)
      update_guild_data(name: name)
    end

    # @return [Array<VoiceRegion>] collection of available voice regions to this guild
    def available_voice_regions
      return @available_voice_regions if @available_voice_regions

      @available_voice_regions = {}

      data = @bot.client.get_guild_voice_regions(@id)
      @available_voice_regions = data.map { |e| VoiceRegion.new e }
    end

    # @return [VoiceRegion, nil] voice region data for this guild's region
    # @note This may return `nil` if this guild's voice region is deprecated.
    def region
      available_voice_regions.find { |e| e.id == @region_id }
    end

    # Moves the guild to another region. This will cause a voice interruption of at most a second.
    # @param region [String] The new region the guild should be in.
    def region=(region)
      update_guild_data(region: region.to_s)
    end

    # Sets the guild's icon.
    # @param icon [String, #read] The new icon, in base64-encoded JPG format.
    def icon=(icon)
      if icon.respond_to? :read
        icon_string = 'data:image/jpg;base64,'
        icon_string += Base64.strict_encode64(icon.read)
        update_guild_data(icon_id: icon_string)
      else
        update_guild_data(icon_id: icon)
      end
    end

    # Sets the guild's AFK channel.
    # @param afk_channel [Channel, nil] The new AFK channel, or `nil` if there should be none set.
    def afk_channel=(afk_channel)
      update_guild_data(afk_channel_id: afk_channel.resolve_id)
    end

    # Sets the guild's system channel.
    # @param system_channel [Channel, String, Integer, nil] The new system channel, or `nil` should it be disabled.
    def system_channel=(system_channel)
      update_guild_data(system_channel_id: system_channel.resolve_id)
    end

    # Sets the amount of time after which a user gets moved into the AFK channel.
    # @param afk_timeout [Integer] The AFK timeout, in seconds.
    def afk_timeout=(afk_timeout)
      update_guild_data(afk_timeout: afk_timeout)
    end

    # A map of possible guild verification levels to symbol names
    VERIFICATION_LEVELS = {
      none: 0,
      low: 1,
      medium: 2,
      high: 3,
      very_high: 4
    }.freeze

    # @return [Symbol] the verification level of the guild (:none = none, :low = 'Must have a verified email on their Discord account', :medium = 'Has to be registered with Discord for at least 5 minutes', :high = 'Has to be a member of this guild for at least 10 minutes', :very_high = 'Must have a verified phone on their Discord account').
    def verification_level
      VERIFICATION_LEVELS.key @verification_level
    end

    # Sets the verification level of the guild
    # @param level [Integer, Symbol] The verification level from 0-4 or Symbol (see {VERIFICATION_LEVELS})
    def verification_level=(level)
      level = VERIFICATION_LEVELS[level] if level.is_a?(Symbol)

      update_guild_data(verification_level: level)
    end

    # A map of possible message notification levels to symbol names
    NOTIFICATION_LEVELS = {
      all_messages: 0,
      only_mentions: 1
    }.freeze

    # @return [Symbol] the default message notifications settings of the guild (:all = 'All messages', :mentions = 'Only @mentions').
    def default_message_notifications
      NOTIFICATION_LEVELS.key @default_message_notifications
    end

    # Sets the default message notification level
    # @param notification_level [Integer, Symbol] The default message notification 0-1 or Symbol (see {NOTIFICATION_LEVELS})
    def default_message_notifications=(notification_level)
      notification_level = NOTIFICATION_LEVELS[notification_level] if notification_level.is_a?(Symbol)

      update_guild_data(default_message_notifications: notification_level)
    end

    alias_method :notification_level=, :default_message_notifications=

    # Sets the guild splash
    # @param splash_hash [String] The splash hash
    def splash=(splash_hash)
      update_guild_data(splash: splash_hash)
    end

    # A map of possible content filter levels to symbol names
    FILTER_LEVELS = {
      disabled: 0,
      members_without_roles: 1,
      all_members: 2
    }.freeze

    # @return [Symbol] the explicit content filter level of the guild (:none = 'Don't scan any messages.', :exclude_roles = 'Scan messages for members without a role.', :all = 'Scan messages sent by all members.').
    def explicit_content_filter
      FILTER_LEVELS.key @explicit_content_filter
    end

    alias_method :content_filter_level, :explicit_content_filter

    # Sets the guild content filter.
    # @param filter_level [Integer, Symbol] The content filter from 0-2 or Symbol (see {FILTER_LEVELS})
    def explicit_content_filter=(filter_level)
      filter_level = FILTER_LEVELS[filter_level] if filter_level.is_a?(Symbol)

      update_guild_data(explicit_content_filter: filter_level)
    end

    # @return [true, false] whether this guild has any emoji or not.
    def any_emoji?
      @emoji.any?
    end

    alias_method :has_emoji?, :any_emoji?
    alias_method :emoji?, :any_emoji?

    # Requests a list of Webhooks on the guild.
    # @return [Array<Webhook>] webhooks on the guild.
    def webhooks
      webhooks = @bot.client.get_guild_webhooks(@id)
      webhooks.map { |webhook| Webhook.new(webhook, @bot) }
    end

    # Requests a list of Invites to the guild.
    # @return [Array<Invite>] invites to the guild.
    def invites
      invites = @bot.client.get_guild_invites(@id)
      invites.map { |invite| Invite.new(invite, @bot) }
    end

    # Processes a GUILD_MEMBERS_CHUNK packet, specifically the members field
    # @note For internal use only
    # @!visibility private
    def process_chunk(members, chunk_index, chunk_count)
      process_members(members)
      LOGGER.debug("Processed chunk #{chunk_index + 1}/#{chunk_count} guild #{@id} - index #{chunk_index} - length #{members.length}")

      return if chunk_index + 1 < chunk_count

      LOGGER.debug("Finished chunking guild #{@id}")

      # Reset everything to normal
      @chunked = true
    end

    # @return [Channel, nil] the AFK voice channel of this guild, or `nil` if none is set.
    def afk_channel
      @bot.channel(@afk_channel_id) if @afk_channel_id
    end

    # @return [Channel, nil] the system channel (used for automatic welcome messages) of a guild, or `nil` if none is set.
    def system_channel
      @bot.channel(@system_channel_id) if @system_channel_id
    end

    # Updates the cached data with new data
    # @note For internal use only
    # @!visibility private
    def update_data(new_data = nil)
      new_data ||= @bot.client.get_guild(@id)
      @name = new_data[:name] || @name
      @region_id = new_data[:region] || @region_id
      @icon_id = new_data[:icon] || @icon_id
      @afk_timeout = new_data[:afk_timeout] || @afk_timeout

      afk_channel_id = new_data[:afk_channel_id] || @afk_channel
      @afk_channel_id = afk_channel_id.nil? ? nil : afk_channel_id.resolve_id
      widget_channel_id = new_data[:widget_channel_id] || @widget_channel
      @widget_channel_id = widget_channel_id.nil? ? nil : widget_channel_id.resolve_id
      system_channel_id = new_data[:system_channel_id] || @system_channel
      @system_channel_id = system_channel_id.nil? ? nil : system_channel_id.resolve_id

      @widget_enabled = new_data[:widget_enabled]
      @splash = new_data[:splash_id] || @splash_id

      @verification_level = new_data[:verification_level] || @verification_level
      @explicit_content_filter = new_data[:explicit_content_filter] || @explicit_content_filter
      @default_message_notifications = new_data[:default_message_notifications] || @default_message_notifications

      @large = new_data.key?(:large) ? new_data[:large] : @large
      @member_count = new_data[:member_count] || @member_count || 0
      @splash_id = new_data[:splash] || @splash_id
      @banner_id = new_data[:banner] || @banner_id
      @features = new_data[:features] ? new_data[:features].map { |element| element.downcase.to_sym } : @features || []

      process_channels(new_data[:channels]) if new_data[:channels]
      process_roles(new_data[:roles]) if new_data[:roles]
      process_emoji(new_data[:emojis]) if new_data[:emojis]
      process_members(new_data[:members]) if new_data[:members]
      process_presences(new_data[:presences]) if new_data[:presences]
      process_voice_states(new_data[:voice_states]) if new_data[:voice_states]
    end

    # Adds a channel to this guild's cache
    # @note For internal use only
    # @!visibility private
    def add_channel(channel)
      @channels << channel
      @channels_by_id[channel.id] = channel
    end

    # Deletes a channel from this guild's cache
    # @note For internal use only
    # @!visibility private
    def delete_channel(id)
      @channels.reject! { |e| e.id == id }
      @channels_by_id.delete(id)
    end

    # Updates the cached emoji data with new data
    # @note For internal use only
    # @!visibility private
    def update_emoji_data(new_data)
      @emoji = {}
      process_emoji(new_data[:emojis])
    end

    # The inspect method is overwritten to give more useful output
    def inspect
      "<Guild name=#{@name} id=#{@id} large=#{@large} region=#{@region} owner=#{@owner} afk_channel_id=#{@afk_channel_id} system_channel_id=#{@system_channel_id} afk_timeout=#{@afk_timeout}>"
    end

    private

    def update_guild_data(new_data)
      resp = @bot.client.modify_guild(@id, **new_data)
      update_data(resp)
    end

    def process_roles(roles)
      # Create roles
      @roles = []
      @roles_by_id = {}

      return unless roles

      roles.each do |element|
        role = Role.new(element, @bot, self)
        @roles << role
        @roles_by_id[role.id] = role
      end
    end

    def process_emoji(emoji)
      return if emoji.empty?

      emoji.each do |element|
        new_emoji = Emoji.new(element, @bot, self)
        @emoji[new_emoji.id] = new_emoji
      end
    end

    def process_members(members)
      return unless members

      members.each do |element|
        member = Member.new(element, self, @bot)
        @members[member.id] = member
      end
    end

    def process_presences(presences)
      # Update user statuses with presence info
      return unless presences

      presences.each do |element|
        next unless element[:user]

        user_id = element[:user][:id].to_i
        user = @members[user_id]
        if user
          user.update_presence(element)
        else
          LOGGER.warn "Rogue presence update! #{element[:user][:id]} on #{@id}"
        end
      end
    end

    def process_channels(channels)
      @channels = []
      @channels_by_id = {}

      return unless channels

      channels.each do |element|
        channel = @bot.ensure_channel(element, self)
        @channels << channel
        @channels_by_id[channel.id] = channel
      end
    end

    def process_voice_states(voice_states)
      return unless voice_states

      voice_states.each do |element|
        update_voice_state(element)
      end
    end
  end

  # A ban entry on a guild
  class GuildBan
    # @return [String, nil] the reason the user was banned, if provided
    attr_reader :reason

    # @return [User] the user that was banned
    attr_reader :user

    # @return [Guild] the guild this ban belongs to
    attr_reader :guild

    # @!visibility private
    def initialize(guild, user, reason)
      @guild = guild
      @user = user
      @reason = reason
    end

    # Removes this ban on the associated user in the guild
    # @param reason [String] the reason for removing the ban
    def remove(reason = nil)
      @guild.unban(user, reason)
    end

    alias_method :unban, :remove
    alias_method :lift, :remove
  end
end