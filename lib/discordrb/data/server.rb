# frozen_string_literal: true

module Discordrb
  # Basic attributes a server should have
  module ServerAttributes
    # @return [String] this server's name.
    attr_reader :name

    # @return [String] the hexadecimal ID used to identify this server's icon.
    attr_reader :icon_id

    # Utility method to get a server's icon URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg`
    #   or `png` to override this.
    # @return [String, nil] The URL to the server's icon, or `nil` if the server hasn't set an icon.
    def icon_url(format: 'webp')
      API.icon_url(@id, @icon_id, format) if @icon_id
    end
  end

  # An isolated collection of channels and member's on Discord.
  class Server
    include IDObject
    include ServerAttributes

    # @return [String] the ID of the region the server is on (e.g. `amsterdam`).
    attr_reader :region_id

    # @return [Array<Channel>] an array of all the channels (text and voice) on this server.
    attr_reader :channels

    # @return [Hash<Integer => Emoji>] a hash of all the emoji available on this server.
    attr_reader :emoji
    alias_method :emojis, :emoji

    # @return [true, false] whether or not this server is large (members > 100). If it is,
    # it means the members list may be inaccurate for a couple seconds after starting up the bot.
    attr_reader :large
    alias_method :large?, :large

    # @return [Array<Symbol>] the features of the server (eg. "INVITE_SPLASH")
    attr_reader :features

    # @return [Integer] the absolute number of members on this server, offline or not.
    attr_reader :member_count

    # @return [Integer] the amount of time after which a voice user gets moved into the AFK channel, in seconds.
    attr_reader :afk_timeout

    # @return [Hash<Integer => VoiceState>] the hash (user ID => voice state) of voice states of members on this server
    attr_reader :voice_states

    # @return [Integer] the server's amount of Nitro boosters, 0 if no one has boosted.
    attr_reader :booster_count

    # @return [Integer] the server's Nitro boost level, 0 if no level.
    attr_reader :boost_level

    # @return [String] the preferred locale of the server. Used in server discovery and notices from Discord.
    attr_reader :locale

    # @return [String, nil] the description of the server. Shown in server discovery and external embeds.
    attr_reader :description

    # @return [String, nil] the hash of the server's banner image or GIF.
    attr_reader :banner_id

    # @return [String, nil] the hash of the server's invite splash image.
    attr_reader :splash_id
    alias_method :splash_hash, :splash_id

    # @return [Integer] the maximum number of members that can join the server.
    attr_reader :max_member_count

    # @return [String, nil] the code of the server's custom vanity invite link.
    attr_reader :vanity_invite_code

    # @return [Integer, nil] the maximum number of members that can concurrently be online in the server.
    #   Always set to `nil` except for the largest of servers.
    attr_reader :max_presence_count

    # @return [String, nil] the hash of the server's discovery splash image.
    attr_reader :discovery_splash_id

    # @return [Integer] the flags for the server's designated system channel.
    attr_reader :system_channel_flags

    # @return [Integer] the maximum number of members that can concurrently watch a stream in a video channel.
    attr_reader :max_video_channel_members

    # @return [Integer] the maximum number of members that can concurrently watch a stream in a stage channel.
    attr_reader :max_stage_video_channel_members

    # @return [true, false] whether or not the server has the boost progress bar enabled.
    attr_reader :boost_progress_bar
    alias_method :boost_progress_bar?, :boost_progress_bar

    # @return [Time, nil] the time at when the last raid was detected on the server.
    attr_reader :raid_detected_at

    # @return [Time, nil] the time at when DM spam was last detected on the server.
    attr_reader :dm_spam_detected_at

    # @return [Time, nil] the time at when invites will be re-enabled on the server.
    attr_reader :invites_disabled_until

    # @return [Time, nil] the time at when non-friend direct messages will be re-enabled on the server.
    attr_reader :dms_disabled_until

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      @members = {}
      @voice_states = {}
      @emoji = {}
      @channels = []
      @channels_by_id = {}
      @scheduled_events = {}
      @automod_rules = {}

      update_data(data)

      # Whether this server's members have been chunked (resolved using op 8 and GUILD_MEMBERS_CHUNK) yet
      @chunked = false
    end

    # @return [Member] The server owner.
    def owner
      member(@owner_id)
    end

    # The default channel is the text channel on this server with the highest position
    # that the bot has Read Messages permission on.
    # @param send_messages [true, false] whether to additionally consider if the bot has Send Messages permission
    # @return [Channel, nil] The default channel on this server, or `nil` if there are no channels that the bot can read.
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

    # @return [Role] The @everyone role on this server
    def everyone_role
      @roles[@id]
    end

    # @return [Array<Role>] an array of all the roles available on this server.
    def roles
      @roles.values
    end

    # Gets a role on this server based on its ID.
    # @param id [String, Integer] The role ID to look for.
    # @return [Role, nil] The role identified by the ID, or `nil` if it couldn't be found.
    def role(id)
      @roles[id.resolve_id]
    end

    # Get a mapping of role IDs to the amount of members who have the role.
    # @example Print out the name of the roles in a server followed by the role's member count.
    #  server = bot.server(81384788765712384)
    #
    #  server.role_member_counts.each do |id, count|
    #    puts("Name: #{server.role(id).name}, Count: #{count}")
    #  end
    # @return [Hash<Integer => Integer>] A hash mapping role IDs to their respective member counts.
    def role_member_counts
      response = JSON.parse(API::Server.role_member_counts(@bot.token, @id))
      response.transform_keys!(&:to_i)
      response.tap { |hash| hash[@id] = @member_count }
    end

    # Gets a member on this server based on user ID
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

    # @return [Array<Member>] an array of all the members on this server.
    # @raise [RuntimeError] if the bot was not started with the :server_member intent
    def members
      return @members.values if @chunked

      @bot.debug("Members for server #{@id} not chunked yet - initiating")

      # If the SERVER_MEMBERS intent flag isn't set, the gateway won't respond when we ask for members.
      raise 'The :server_members intent is required to get server members' if @bot.gateway.intents.nobits?(INTENTS[:server_members])

      @bot.request_chunks(@id)
      sleep 0.05 until @chunked
      @members.values
    end

    alias_method :users, :members

    # @return [Array<Member>] an array of all the bot members on this server.
    def bot_members
      members.select(&:bot_account?)
    end

    # @return [Array<Member>] an array of all the non bot members on this server.
    def non_bot_members
      members.reject(&:bot_account?)
    end

    # @return [Member] the bot's own `Member` on this server
    def bot
      member(@bot.profile)
    end

    # @return [Array<Integration>] an array of the integrations in this server.
    # @note If the server has more than 50 integrations, they cannot be accessed.
    def integrations
      integration = JSON.parse(API::Server.integrations(@bot.token, @id))
      integration.map { |element| Integration.new(element, @bot, self) }
    end

    # @param action [Symbol] The action to only include.
    # @param user [User, String, Integer] The user, or their ID, to filter entries to.
    # @param limit [Integer] The amount of entries to limit it to.
    # @param before [Entry, String, Integer] The entry, or its ID, to use to not include all entries after it.
    # @return [AuditLogs] The server's audit logs.
    def audit_logs(action: nil, user: nil, limit: 50, before: nil)
      raise 'Invalid audit log action!' if action && AuditLogs::ACTIONS.key(action).nil?

      action = AuditLogs::ACTIONS.key(action)
      user = user.resolve_id if user
      before = before.resolve_id if before
      AuditLogs.new(self, @bot, JSON.parse(API::Server.audit_logs(@bot.token, @id, limit, user, action, before)))
    end

    # Cache @widget
    # @note For internal use only
    # @!visibility private
    def cache_widget_data
      data = JSON.parse(API::Server.widget(@bot.token, @id))
      @widget_enabled = data['enabled']
      @widget_channel_id = data['channel_id']
    end

    # @return [true, false] whether or not the server has widget enabled
    def widget_enabled?
      cache_widget_data if @widget_enabled.nil?
      @widget_enabled
    end
    alias_method :widget?, :widget_enabled?
    alias_method :embed_enabled, :widget_enabled?
    alias_method :embed?, :widget_enabled?

    # @return [Channel, nil] the channel the server widget will make an invite for.
    def widget_channel
      cache_widget_data if @widget_enabled.nil?
      @bot.channel(@widget_channel_id) if @widget_channel_id
    end
    alias_method :embed_channel, :widget_channel

    # Sets whether this server's widget is enabled
    # @param value [true, false]
    def widget_enabled=(value)
      modify_widget(value, widget_channel)
    end
    alias_method :embed_enabled=, :widget_enabled=

    # Sets whether this server's widget is enabled
    # @param value [true, false]
    # @param reason [String, nil] the reason to be shown in the audit log for this action
    def set_widget_enabled(value, reason = nil)
      modify_widget(value, widget_channel, reason)
    end
    alias_method :set_embed_enabled, :set_widget_enabled

    # Changes the channel on the server's widget
    # @param channel [Channel, String, Integer] the channel, or its ID, to be referenced by the widget
    def widget_channel=(channel)
      modify_widget(widget?, channel)
    end
    alias_method :embed_channel=, :widget_channel=

    # Changes the channel on the server's widget
    # @param channel [Channel, String, Integer] the channel, or its ID, to be referenced by the widget
    # @param reason [String, nil] the reason to be shown in the audit log for this action
    def set_widget_channel(channel, reason = nil)
      modify_widget(widget?, channel, reason)
    end
    alias_method :set_embed_channel, :set_widget_channel

    # Changes the channel on the server's widget, and sets whether it is enabled.
    # @param enabled [true, false] whether the widget is enabled
    # @param channel [Channel, String, Integer] the channel, or its ID, to be referenced by the widget
    # @param reason [String, nil] the reason to be shown in the audit log for this action
    def modify_widget(enabled, channel, reason = nil)
      cache_widget_data if @widget_enabled.nil?
      channel_id = channel ? channel.resolve_id : @widget_channel_id
      response = JSON.parse(API::Server.modify_widget(@bot.token, @id, enabled, channel_id, reason))
      @widget_enabled = response['enabled']
      @widget_channel_id = response['channel_id']
    end
    alias_method :modify_embed, :modify_widget

    # @param include_idle [true, false] Whether to count idle members as online.
    # @param include_bots [true, false] Whether to include bot accounts in the count.
    # @return [Array<Member>] an array of online members on this server.
    def online_members(include_idle: false, include_bots: true)
      @members.values.select do |e|
        ((include_idle ? e.idle? : false) || e.online?) && (include_bots ? true : !e.bot_account?)
      end
    end

    alias_method :online_users, :online_members

    # Adds a member to this guild that has granted this bot's application an OAuth2 access token
    # with the `guilds.join` scope.
    # For more information about Discord's OAuth2 implementation, see: https://discord.com/developers/docs/topics/oauth2
    # @note Your bot must be present in this server, and have permission to create instant invites for this to work.
    # @param user [User, String, Integer] the user, or ID of the user to add to this server
    # @param access_token [String] the OAuth2 Bearer token that has been granted the `guilds.join` scope
    # @param nick [String] the nickname to give this member upon joining
    # @param roles [Role, Array<Role, String, Integer>] the role (or roles) to give this member upon joining
    # @param deaf [true, false] whether this member will be server deafened upon joining
    # @param mute [true, false] whether this member will be server muted upon joining
    # @return [Member, nil] the created member, or `nil` if the user is already a member of this server.
    def add_member_using_token(user, access_token, nick: nil, roles: [], deaf: false, mute: false)
      user_id = user.resolve_id
      roles = roles.is_a?(Array) ? roles.map(&:resolve_id) : [roles.resolve_id]
      response = API::Server.add_member(@bot.token, @id, user_id, access_token, nick, roles, deaf, mute)
      return nil if response.empty?

      add_member Member.new(JSON.parse(response), self, @bot)
    end

    # Returns the amount of members that are candidates for pruning
    # @param days [Integer] the number of days to consider for inactivity
    # @return [Integer] number of members to be removed
    # @raise [ArgumentError] if days is not between 1 and 30 (inclusive)
    def prune_count(days)
      raise ArgumentError, 'Days must be between 1 and 30' unless days.between?(1, 30)

      response = JSON.parse API::Server.prune_count(@bot.token, @id, days)
      response['pruned']
    end

    # Prunes (kicks) an amount of members for inactivity
    # @param days [Integer] the number of days to consider for inactivity (between 1 and 30)
    # @param reason [String] The reason the for the prune.
    # @return [Integer] the number of members removed at the end of the operation
    # @raise [ArgumentError] if days is not between 1 and 30 (inclusive)
    def begin_prune(days, reason = nil)
      raise ArgumentError, 'Days must be between 1 and 30' unless days.between?(1, 30)

      response = JSON.parse API::Server.begin_prune(@bot.token, @id, days, reason)
      response['pruned']
    end

    alias_method :prune, :begin_prune

    # @return [Array<Channel>] an array of text channels on this server
    def text_channels
      @channels.select(&:text?)
    end

    # @return [Array<Channel>] an array of voice channels on this server
    def voice_channels
      @channels.select(&:voice?)
    end

    # @return [Array<Channel>] an array of category channels on this server
    def categories
      @channels.select(&:category?)
    end

    # @return [Array<Channel>] an array of channels on this server that are not in a category
    def orphan_channels
      @channels.reject { |c| c.parent || c.category? }
    end

    # @return [ServerPreview] the preview of this server shown in the discovery page.
    def preview
      @bot.server_preview(@id)
    end

    # @return [String, nil] the widget URL to the server that displays the amount of online members in a
    #   stylish way. `nil` if the widget is not enabled.
    def widget_url
      update_data if @widget_enabled.nil?

      API.widget_url(@id) if @widget_enabled
    end

    # @param style [Symbol] The style the picture should have. Possible styles are:
    #   * `:banner1` creates a rectangular image with the server name, member count and icon, a "Powered by Discord" message on the bottom and an arrow on the right.
    #   * `:banner2` creates a less tall rectangular image that has the same information as `banner1`, but the Discord logo on the right - together with the arrow and separated by a diagonal separator.
    #   * `:banner3` creates an image similar in size to `banner1`, but it has the arrow in the bottom part, next to the Discord logo and with a "Chat now" text.
    #   * `:banner4` creates a tall, almost square, image that prominently features the Discord logo at the top and has a "Join my server" in a pill-style button on the bottom. The information about the server is in the same format as the other three `banner` styles.
    #   * `:shield` creates a very small, long rectangle, of the style you'd find at the top of GitHub `README.md` files. It features a small version of the Discord logo at the left and the member count at the right.
    # @return [String, nil] the widget banner URL to the server that displays the amount of online members,
    #   server icon and server name in a stylish way. `nil` if the widget is not enabled.
    def widget_banner_url(style)
      update_data if @widget_enabled.nil?

      API.widget_url(@id, style) if @widget_enabled
    end

    # Utility method to get a server's splash URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to
    #   override this.
    # @return [String, nil] The URL to the server's splash image, or `nil` if the server doesn't have a splash image.
    def splash_url(format: 'webp')
      API.splash_url(@id, @splash_id, format) if @splash_id
    end

    # Utility method to get a server's banner URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to
    #   override this.
    # @return [String, nil] The URL to the server's banner image, or `nil` if the server doesn't have a banner image.
    def banner_url(format: 'webp')
      API.banner_url(@id, @banner_id, format) if @banner_id
    end

    # Utility method to get a server's discovery splash URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @return [String, nil] The URL to the server's discovery splash image, or `nil` if the server doesn't have a discovery splash image.
    def discovery_splash_url(format: 'webp')
      API.discovery_splash_url(@id, @discovery_splash_id, format) if @discovery_splash_id
    end

    # @return [String] a URL that a user can use to navigate to this server in the client
    def link
      "https://discord.com/channels/#{@id}"
    end

    alias_method :jump_link, :link

    # Adds a role to the role cache
    # @note For internal use only
    # @!visibility private
    def add_role(role)
      @roles[role.id] = role
    end

    # Removes a role from the role cache
    # @note For internal use only
    # @!visibility private
    def delete_role(role_id)
      @roles.delete(role_id.resolve_id)
      @members.each_value do |member|
        new_roles = member.roles.reject { |r| r.id == role_id }
        member.update_roles(new_roles)
      end
      @channels.each do |channel|
        overwrites = channel.permission_overwrites.reject { |id, _| id == role_id }
        channel.update_overwrites(overwrites)
      end
    end

    # Updates the positions of all roles on the server
    # @note For internal use only
    # @!visibility private
    def update_role_positions(role_positions, reason: nil)
      response = JSON.parse(API::Server.update_role_positions(@bot.token, @id, role_positions, reason))
      response.each { |data| role(data['id'].to_i)&.update_data(data) }
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

    # Adds a scheduled event to the cache
    # @note For internal use only
    # @!visibility private
    def cache_scheduled_event(event)
      @scheduled_events[event.id] = event
    end

    # Removes a scheduled event from the cache.
    # @note For internal use only
    # @!visibility private
    def delete_scheduled_event(event)
      @scheduled_events.delete(event.resolve_id)
    end

    # Updates a member's voice state
    # @note For internal use only
    # @!visibility private
    def update_voice_state(data)
      user_id = data['user_id'].to_i

      if data['channel_id']
        unless @voice_states[user_id]
          # Create a new voice state for the user
          @voice_states[user_id] = VoiceState.new(user_id)
        end

        # Update the existing voice state (or the one we just created)
        channel = @channels_by_id[data['channel_id'].to_i]
        @voice_states[user_id].update(
          channel,
          data['mute'],
          data['deaf'],
          data['self_mute'],
          data['self_deaf']
        )
      else
        # The user is not in a voice channel anymore, so delete its voice state
        @voice_states.delete(user_id)
      end
    end

    # Add an automod rule to the cache.
    # @note For internal use only
    # @!visibility private
    def cache_automod_rule(rule)
      @automod_rules[rule.id] = rule
    end

    # Delete an existing automod rule from the cache.
    # @note For internal use only
    # @!visibility private
    def delete_automod_rule(rule)
      @automod_rules.delete(rule.resolve_id)
    end

    # Creates a channel on this server with the given name.
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
      response = API::Server.create_channel(@bot.token, @id, name, type, topic, bitrate, user_limit, permission_overwrites, parent_id, nsfw, rate_limit_per_user, position, reason)
      Channel.new(JSON.parse(response), @bot)
    end

    # Creates a role on this server which can then be modified. It will be initialized
    # with the regular role defaults the client uses unless specified, i.e. name is "new role",
    # permissions are the default, colour is the default etc.
    # @param name [String] Name of the role to create.
    # @param colour [Integer, ColourRGB, #combined] The primary colour of the role to create.
    # @param hoist [true, false] whether members of this role should be displayed seperately in the members list.
    # @param mentionable [true, false] whether this role can mentioned by anyone in the server.
    # @param permissions [Integer, Array<Symbol>, Permissions, #bits] The permissions to write to the new role.
    # @param icon [String, #read, nil] The base64 encoded image data, or a file like object that responds to #read.
    # @param unicode_emoji [String, nil] The unicode emoji of the role to create, or nil.
    # @param display_icon [String, File, #read, nil] The icon to display for the role. Overrides the **icon** and **unicode_emoji** parameters if passed.
    # @param reason [String] The reason the for the creation of this role.
    # @param secondary_colour [Integer, ColourRGB, nil] The secondary colour of the role to create.
    # @param tertiary_colour [Integer, ColourRGB, nil] The tertiary colour of the role to create.
    # @return [Role] the created role.
    def create_role(name: 'new role', colour: 0, hoist: false, mentionable: false, permissions: 104_324_161, secondary_colour: nil, tertiary_colour: nil, icon: nil, unicode_emoji: nil, display_icon: nil, reason: nil)
      colour = colour.respond_to?(:combined) ? colour.combined : colour

      permissions = if permissions.is_a?(Array)
                      Permissions.bits(permissions)
                    elsif permissions.respond_to?(:bits)
                      permissions.bits
                    else
                      permissions
                    end

      icon = icon.respond_to?(:read) ? Discordrb.encode64(icon) : icon

      colours = {
        primary_color: colour&.to_i,
        tertiary_color: tertiary_colour&.to_i,
        secondary_color: secondary_colour&.to_i
      }

      if display_icon.is_a?(String)
        unicode_emoji = display_icon
      elsif display_icon.respond_to?(:read)
        icon = Discordrb.encode64(display_icon)
      end

      response = API::Server.create_role(@bot.token, @id, name, nil, hoist, mentionable, permissions&.to_s, reason, colours, icon, unicode_emoji)

      role = Role.new(JSON.parse(response), @bot, self)
      @roles[role.id] = role
    end

    # Adds a new custom emoji on this server.
    # @param name [String] The name of emoji to create.
    # @param image [String, #read] A base64 encoded string with the image data, or an object that responds to `#read`, such as `File`.
    # @param roles [Array<Role, String, Integer>] An array of roles, or role IDs to be whitelisted for this emoji.
    # @param reason [String] The reason the for the creation of this emoji.
    # @return [Emoji] The emoji that has been added.
    def add_emoji(name, image, roles = [], reason: nil)
      image = image.respond_to?(:read) ? Discordrb.encode64(image) : image

      data = JSON.parse(API::Server.add_emoji(@bot.token, @id, image, name, roles.map(&:resolve_id), reason))
      new_emoji = Emoji.new(data, @bot, self)
      @emoji[new_emoji.id] = new_emoji
    end

    # Delete a custom emoji on this server
    # @param emoji [Emoji, String, Integer] The emoji or emoji ID to be deleted.
    # @param reason [String] The reason the for the deletion of this emoji.
    def delete_emoji(emoji, reason: nil)
      API::Server.delete_emoji(@bot.token, @id, emoji.resolve_id, reason)
    end

    # Changes the name and/or role whitelist of an emoji on this server.
    # @param emoji [Emoji, String, Integer] The emoji or emoji ID to edit.
    # @param name [String] The new name for the emoji.
    # @param roles [Array<Role, String, Integer>] A new array of roles, or role IDs, to whitelist.
    # @param reason [String] The reason for the editing of this emoji.
    # @return [Emoji] The edited emoji.
    def edit_emoji(emoji, name: nil, roles: nil, reason: nil)
      emoji = @emoji[emoji.resolve_id]
      data = JSON.parse(API::Server.edit_emoji(@bot.token, @id, emoji.resolve_id, name || emoji.name, (roles || emoji.roles).map(&:resolve_id), reason))
      new_emoji = Emoji.new(data, @bot, self)
      @emoji[new_emoji.id] = new_emoji
    end

    # The amount of emoji the server can have, based on its current Nitro Boost Level.
    # @return [Integer] the max amount of emoji
    def max_emoji
      case @boost_level
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

    # Get a single automod rule.
    # @param rule_id [Integer, String, AutoModRule] The ID of the automod rule to get.
    # @param request [true, false] Whether the automod rule should be requested from Discord if it isn't cached.
    # @return [AutoModRule, nil] the automod rule that was found, or `nil`.
    def automod_rule(rule_id, request: true)
      id = rule_id.resolve_id
      return @automod_rules[id] if @automod_rules[id] && @bot.gateway.intents.anybits?(INTENTS[:server_automod])
      return nil unless request

      data = JSON.parse(API::Server.get_automod_rule(@bot.token, @id, id))
      rule = AutoModRule.new(data, self, @bot)
      @automod_rules[rule.resolve_id] = rule
    rescue StandardError
      nil
    end

    # Get a list of all the automod rules configured on this server.
    # @param bypass_cache [true, false] Whether the cached automod rules
    #   should be ignored and re-fetched via an HTTP request.
    # @return [Array<AutoModRule>] the configured automod rules on this server.
    def automod_rules(bypass_cache: false)
      return @automod_rules.values if @rules_cached && !bypass_cache

      response = JSON.parse(API::Server.list_automod_rules(@bot.token, @id))

      response.each do |element|
        rule = AutoModRule.new(element, self, @bot)
        @automod_rules[rule.id] = rule
      end

      (@rules_cached = true) if @bot.gateway.intents.anybits?(INTENTS[:server_automod])
      @automod_rules.values
    rescue StandardError
      []
    end

    # Create an auto moderation rule. Requires the `manage_server` permission.
    # @param name [String] The name of the auto moderation rule.
    # @param event_type [Integer, Symbol] The event type of the auto moderation rule.
    # @param trigger_type [Integer, Symbol] The trigger type of the auto moderation rule.
    # @param actions [Array<#to_h>] The actions to execute when the auto moderation rule is triggered.
    # @param enabled [true, false, nil] Whether to enable the auto moderation rule.
    # @param exempt_roles [Array<#resolve_id>, nil] The exempt roles of the auto moderation rule; max 20.
    # @param exempt_channels [Array<#resolve_id>, nil] The exempt channels of the auto moderation rule; max 50.
    # @param keyword_filter [Array<String>, nil] The substrings that should trigger the auto moderation rule.
    # @param regex_patterns [Array<String>, nil] The Rust flavoured regex patterns that should trigger the auto moderation rule.
    # @param keyword_presets [Array<Integer, Symbol>, nil] The of word types that can trigger the auto moderation rule.
    # @param exempt_keywords [Array<String>, nil] The substrings that should not trigger the auto moderation rule.
    # @param mention_limit [Integer, nil] The number of unique mentions that should trigger the auto moderation rule.
    # @param mention_raid_protection [true, false, nil] If mention raids should be auto-detected by the auto moderation rule.
    # @param reason [String, nil] The reason for creating the auto moderation rule.
    # @yieldparam builder [AutoModRule::Action::Builder] An optional builder for auto moderation actions.
    # @return [AutoModRule] the newly created auto moderation rule.
    def create_automod_rule(name:, event_type:, trigger_type:, actions: [], enabled: false, exempt_roles: nil, exempt_channels: nil, keyword_filter: nil, regex_patterns: nil, keyword_presets: nil, exempt_keywords: nil, mention_limit: nil, mention_raid_protection: nil, reason: nil)
      yield((builder = AutoModRule::Action::Builder.new)) if block_given?

      trigger = {
        allow_list: exempt_keywords,
        keyword_filter: keyword_filter,
        regex_patterns: regex_patterns,
        mention_total_limit: mention_limit,
        mention_raid_protection_enabled: mention_raid_protection,
        presets: keyword_presets&.map { |type| AutoModRule::Trigger::PRESET_TYPES[type] || type }
      }.compact

      data = {
        name: name,
        enabled: enabled,
        exempt_roles: exempt_roles&.map(&:resolve_id),
        trigger_metadata: trigger.empty? ? nil : trigger,
        exempt_channels: exempt_channels&.map(&:resolve_id),
        actions: block_given? ? builder&.to_a : actions.map(&:to_h),
        event_type: AutoModRule::EVENT_TYPES[event_type] || event_type,
        trigger_type: AutoModRule::Trigger::TYPES[trigger_type] || trigger_type
      }

      rule = JSON.parse(API::Server.create_automod_rule(@bot.token, @id, **data, reason: reason))
      AutoModRule.new(rule, self, @bot).tap { |rule| cache_automod_rule(rule) }
    end

    # Searches a server for members that matches a username or a nickname.
    # @param name [String] The username or nickname to search for.
    # @param limit [Integer] The maximum number of members between 1-1000 to return. Returns 1 member by default.
    # @return [Array<Member>, nil] An array of member objects that match the given parameters, or nil for no members.
    def search_members(name:, limit: nil)
      response = JSON.parse(API::Server.search_guild_members(@bot.token, @id, name, limit))
      return nil if response.empty?

      response.map { |mem| Member.new(mem, self, @bot) }
    end

    # Retrieve banned users from this server.
    # @param limit [Integer] Number of users to return (up to maximum 1000, default 1000).
    # @param before_id [Integer] Consider only users before given user id.
    # @param after_id [Integer] Consider only users after given user id.
    # @return [Array<ServerBan>] a list of banned users on this server and the reason they were banned.
    def bans(limit: nil, before_id: nil, after_id: nil)
      response = JSON.parse(API::Server.bans(@bot.token, @id, limit, before_id, after_id))
      response.map do |e|
        ServerBan.new(self, @bot.ensure_user(e['user']), e['reason'])
      end
    end

    # Get the users who have been banned from the server.
    # @param limit [Integer, nil] The max number of bans to return, or `nil` for no limit.
    # @param after [User, Member, Time, Integer, String, nil] Get bans after this user ID.
    # @param before [User, Member, Time, Integer, String, nil] Get bans before this user ID.
    # @return [Array<ServerBan>] The users who have been banned from the server.
    # @note When using the `before` parameter, bans will be sorted in descending order by user ID
    #   (newest users first), and in ascending order by user ID (oldest users first) otherwise.
    def bans!(limit: 1000, before: nil, after: nil)
      raise ArgumentError, "'before' and 'after' are mutually exclusive" if before && after

      f_limit = limit && limit <= 1000 ? limit : 1000
      f_after = after.is_a?(Time) ? IDObject.synthesize(after) : after&.resolve_id
      f_before = before.is_a?(Time) ? IDObject.synthesize(before) : before&.resolve_id

      get_bans = lambda do |before: nil, after: nil|
        data = API::Server.bans(@bot.token, @id, f_limit, before&.id || f_before, after&.id || f_after)
        JSON.parse(data).map { |ban| ServerBan.new(self, @bot.ensure_user(ban['user']), ban['reason']) }
      end

      paginator = Paginator.new(limit, before ? :up : :down) do |page|
        if before
          get_bans.call(before: page&.first&.user)
        else
          get_bans.call(after: page&.last&.user)
        end
      end

      paginator.to_a
    end

    # Bans a user from this server.
    # @param user [User, String, Integer] The user to ban.
    # @param message_days [Integer] How many days worth of messages sent by the user should be deleted. This is deprecated and will be removed in 4.0.
    # @param message_seconds [Integer] How many seconds of messages sent by the user should be deleted.
    # @param reason [String] The reason the user is being banned.
    def ban(user, message_days = 0, message_seconds: nil, reason: nil)
      delete_messages = if message_days != 0 && message_days
                          message_days * 86_400
                        else
                          message_seconds || 0
                        end

      API::Server.ban_user!(@bot.token, @id, user.resolve_id, delete_messages, reason)
    end

    # Unbans a previously banned user from this server.
    # @param user [User, String, Integer] The user to unban.
    # @param reason [String] The reason the user is being unbanned.
    def unban(user, reason = nil)
      API::Server.unban_user(@bot.token, @id, user.resolve_id, reason)
    end

    # Ban up to 200 users from this server in one go.
    # @param users [Array<User, String, Integer>] Array of up to 200 users to ban.
    # @param message_seconds [Integer] How many seconds of messages sent by the users should be deleted.
    # @param reason [String] The reason these users are being banned.
    # @return [BulkBan]
    def bulk_ban(users:, message_seconds: 0, reason: nil)
      raise ArgumentError, 'Can only ban between 1 and 200 users!' unless users.size.between?(1, 200)

      return ban(users.first, 0, message_seconds: message_seconds, reason: reason) if users.size == 1

      response = API::Server.bulk_ban(@bot.token, @id, users.map(&:resolve_id), message_seconds, reason)
      BulkBan.new(JSON.parse(response), self, reason)
    end

    # Kicks a user from this server.
    # @param user [User, String, Integer] The user to kick.
    # @param reason [String] The reason the user is being kicked.
    def kick(user, reason = nil)
      API::Server.remove_member(@bot.token, @id, user.resolve_id, reason)
    end

    # Forcibly moves a user into a different voice channel.
    # Only works if the bot has the permission needed and if the user is already connected to some voice channel on this server.
    # @param user [User, String, Integer] The user to move.
    # @param channel [Channel, String, Integer, nil] The voice channel to move into. (If nil, the user is disconnected from the voice channel)
    def move(user, channel)
      API::Server.update_member(@bot.token, @id, user.resolve_id, channel_id: channel&.resolve_id)
    end

    # Leave the server.
    def leave
      API::User.leave_server(@bot.token, @id)
    end

    # Sets the server's name.
    # @param name [String] The new server name.
    def name=(name)
      modify(name: name)
    end

    # @return [Array<VoiceRegion>] collection of available voice regions to this guild
    def available_voice_regions
      return @available_voice_regions if @available_voice_regions

      @available_voice_regions = {}

      data = JSON.parse API::Server.regions(@bot.token, @id)
      @available_voice_regions = data.map { |e| VoiceRegion.new e }
    end

    # @return [VoiceRegion, nil] voice region data for this server's region
    # @note This may return `nil` if this server's voice region is deprecated.
    def region
      available_voice_regions.find { |e| e.id == @region_id }
    end

    # Moves the server to another region. This will cause a voice interruption of at most a second.
    # @param region [String] The new region the server should be in.
    def region=(region)
      update_data(JSON.parse(API::Server.update!(@bot.token, @id, region: region.to_s)))
    end

    # Sets the server's icon.
    # @param icon [String, #read, nil] The new icon, in base64-encoded JPG format.
    def icon=(icon)
      modify(icon: icon)
    end

    # Sets the server's AFK channel.
    # @param afk_channel [Channel, nil] The new AFK channel, or `nil` if there should be none set.
    def afk_channel=(afk_channel)
      modify(afk_channel: afk_channel)
    end

    # Sets the server's system channel.
    # @param system_channel [Channel, String, Integer, nil] The new system channel, or `nil` should it be disabled.
    def system_channel=(system_channel)
      modify(system_channel: system_channel)
    end

    # Sets the amount of time after which a user gets moved into the AFK channel.
    # @param afk_timeout [Integer] The AFK timeout, in seconds.
    def afk_timeout=(afk_timeout)
      modify(afk_timeout: afk_timeout)
    end

    # A map of possible server verification levels to symbol names
    VERIFICATION_LEVELS = {
      none: 0,
      low: 1,
      medium: 2,
      high: 3,
      very_high: 4
    }.freeze

    # @return [Symbol] The verification level of the server (:none = none, :low = 'Must have a verified email on their Discord account', :medium = 'Has to be registered with Discord for at least 5 minutes', :high = 'Has to be a member of this server for at least 10 minutes', :very_high = 'Must have a verified phone on their Discord account').
    def verification_level
      VERIFICATION_LEVELS.key(@verification_level)
    end

    # Sets the verification level of the server
    # @param level [Integer, Symbol] The verification level from 0-4 or Symbol (see {VERIFICATION_LEVELS})
    def verification_level=(level)
      modify(verification_level: level)
    end

    # A map of possible message notification levels to symbol names
    NOTIFICATION_LEVELS = {
      all_messages: 0,
      only_mentions: 1
    }.freeze

    # @return [Symbol] The default message notifications settings of the server (:all_messages = 'All messages', :only_mentions = 'Only @mentions').
    def default_message_notifications
      NOTIFICATION_LEVELS.key(@default_message_notifications)
    end

    # Sets the default message notification level
    # @param notification_level [Integer, Symbol] The default message notification 0-1 or Symbol (see {NOTIFICATION_LEVELS})
    def default_message_notifications=(notification_level)
      modify(notification_level: notification_level)
    end

    alias_method :notification_level=, :default_message_notifications=

    # A map of possible content filter levels to symbol names
    FILTER_LEVELS = {
      disabled: 0,
      members_without_roles: 1,
      all_members: 2
    }.freeze

    # @return [Symbol] The explicit content filter level of the server (:disabled = 'Don't scan any messages.', :members_without_roles = 'Scan messages for members without a role.', :all_members = 'Scan messages sent by all members.').
    def explicit_content_filter
      FILTER_LEVELS.key(@explicit_content_filter)
    end

    alias_method :content_filter_level, :explicit_content_filter

    # Sets the server content filter.
    # @param filter_level [Integer, Symbol] The content filter from 0-2 or Symbol (see {FILTER_LEVELS})
    def explicit_content_filter=(filter_level)
      modify(explicit_content_filter: filter_level)
    end

    # A map of possible multi-factor authentication levels to symbol names
    MFA_LEVELS = {
      none: 0,
      elevated: 1
    }.freeze

    # @return [Symbol] The multi-factor authentication level of the server (:none = 'no MFA/2FA requirement for moderation actions', :elevated = 'MFA/2FA is required for moderation actions')
    def mfa_level
      MFA_LEVELS.key @mfa_level
    end

    # A map of possible NSFW levels to symbol names
    NSFW_LEVELS = {
      default: 0,
      explicit: 1,
      safe: 2,
      age_restricted: 3
    }.freeze

    # @return [Symbol] The NSFW level of the server (:default = 'no NSFW level has been set', :explicit = 'the server may contain explicit content', :safe = 'the server does not contain NSFW content', :age_restricted = 'server membership is restricted to adults')
    def nsfw_level
      NSFW_LEVELS.key @nsfw_level
    end

    # @return [true, false] whether this server has any emoji or not.
    def any_emoji?
      @emoji.any?
    end

    alias_method :has_emoji?, :any_emoji?
    alias_method :emoji?, :any_emoji?

    # Create an invite link using the server's vanity code.
    # @return [String, nil] The server's vanity invite URL, or `nil` if the server does not have a vanity invite code.
    def vanity_invite_url
      return unless @vanity_invite_code

      "https://discord.gg/#{@vanity_invite_code}"
    end

    alias_method :vanity_invite_link, :vanity_invite_url

    # Check if the auto-moderation system has detected a raid.
    # @return [true, false] Whether or not Discord's anti-spam system has detected a raid in the server.
    def raid_detected?
      !@raid_detected_at.nil?
    end

    # Check if the auto-moderation system has detected DM spam.
    # @return [true, false] Whether or not Discord's anti-spam system has detected dm-spam in the server.
    def dm_spam_detected?
      !@dm_spam_detected_at.nil?
    end

    # Check if the server has disabled non-friend DMs.
    # @return [true, false] Whether or not the server has stopped member's who aren't friends from DMing each other.
    def dms_disabled?
      !@dms_disabled_until.nil? && @dms_disabled_until > Time.now
    end

    # Check if the server has paused invites.
    # @return [true, false] Whether or not the server has stopped new members from joining, either via incident actions
    #   or the `:invites_disabled` feature.
    def invites_disabled?
      (!@invites_disabled_until.nil? && @invites_disabled_until > Time.now) || @features.include?(:invites_disabled)
    end

    # Requests a list of Webhooks on the server.
    # @return [Array<Webhook>] webhooks on the server.
    def webhooks
      webhooks = JSON.parse(API::Server.webhooks(@bot.token, @id))
      webhooks.map { |webhook| Webhook.new(webhook, @bot) }
    end

    # Requests a list of Invites to the server.
    # @return [Array<Invite>] invites to the server.
    def invites
      invites = JSON.parse(API::Server.invites(@bot.token, @id))
      invites.map { |invite| Invite.new(invite, @bot) }
    end

    # Get the scheduled events on the server.
    # @param bypass_cache [true, false] Whether the cached scheduled events
    #   should be ignored and re-fetched via an HTTP request.
    # @return [Array<ScheduledEvent>] The scheduled events on the server.
    def scheduled_events(bypass_cache: false)
      process_scheduled_events(JSON.parse(API::Server.list_scheduled_events(@bot.token, @id, with_user_count: true))) if bypass_cache

      @scheduled_events.values
    end

    # Get a specific scheduled event on the server.
    # @param scheduled_event_id [Integer, String, ScheduledEvent] The scheduled event to get.
    # @param request [true, false] Whether to request the event from discord if it isn't cached.
    # @return [ScheduledEvent, nil] The scheduled event for the ID, or `nil` if it couldn't be found.
    def scheduled_event(scheduled_event_id, request: true)
      id = scheduled_event_id.resolve_id
      return @scheduled_events[id] if @scheduled_events[id]
      return nil unless request

      event = JSON.parse(API::Server.get_scheduled_event(@bot.token, @id, id, with_user_count: true))
      scheduled_event = ScheduledEvent.new(event, self, @bot)
      @scheduled_events[scheduled_event.id] = scheduled_event
    rescue StandardError
      nil
    end

    # Create a scheduled event on this server.
    # @param name [String] The 1-100 character name of the scheduled event to create.
    # @param start_time [Time] The start time of the scheduled event to create.
    # @param entity_type [Integer, Symbol] The entity type of the scheduled event to create.
    # @param end_time [Time, nil] The end time of the scheduled event to create.
    # @param channel [Integer, Channel, String, nil] The channel where the scheduled event will take place.
    # @param location [String, nil] The external location of the scheduled event to create.
    # @param description [String, nil] The 1-100 character description of the scheduled event to create.
    # @param cover [File, #read, nil] The cover image of the scheduled event to create.
    # @param recurrence_rule [#to_h, nil] The recurrence rule of the scheduled event to create.
    # @param reason [String, nil] The audit log reason for creating the scheduled event.
    # @yieldparam builder [ScheduledEvent::RecurrenceRule::Builder] An optional reccurence rule builder.
    # @return [ScheduledEvent] the scheduled event that was created.
    def create_scheduled_event(name:, start_time:, entity_type:, end_time: nil, channel: nil, location: nil, description: nil, cover: nil, recurrence_rule: nil, reason: nil)
      yield((builder = ScheduledEvent::RecurrenceRule::Builder.new)) if block_given?

      options = {
        name: name,
        privacy_level: 2,
        scheduled_start_time: start_time&.iso8601,
        entity_type: ScheduledEvent::ENTITY_TYPES[entity_type] || entity_type,
        channel_id: channel&.resolve_id,
        entity_metadata: location ? { location: location } : nil,
        scheduled_end_time: end_time&.iso8601,
        description: description,
        image: cover.respond_to?(:read) ? Discordrb.encode64(cover) : cover,
        recurrence_rule: block_given? ? builder.to_h : recurrence_rule&.to_h
      }

      event = JSON.parse(API::Server.create_scheduled_event(@bot.token, @id, **options, reason: reason))
      scheduled_event = ScheduledEvent.new(event, self, @bot)
      @scheduled_events[scheduled_event.id] = scheduled_event
    end

    # Processes a GUILD_MEMBERS_CHUNK packet, specifically the members field
    # @note For internal use only
    # @!visibility private
    def process_chunk(members, chunk_index, chunk_count)
      process_members(members)
      LOGGER.debug("Processed chunk #{chunk_index + 1}/#{chunk_count} server #{@id} - index #{chunk_index} - length #{members.length}")

      return if chunk_index + 1 < chunk_count

      LOGGER.debug("Finished chunking server #{@id}")

      # Reset everything to normal
      @chunked = true
    end

    # Get the AFK channel of the server.
    # @return [Channel, nil] the AFK voice channel of this server, or `nil` if none is set.
    def afk_channel
      @bot.channel(@afk_channel_id) if @afk_channel_id
    end

    # Get the rules channel of the server.
    # @return [Channel, nil] The channel where community servers can display rules or guidelines, or `nil` if none is set.
    def rules_channel
      @bot.channel(@rules_channel_id) if @rules_channel_id
    end

    # Get the system channel of the server.
    # @return [Channel, nil] The system channel (used for automatic welcome messages) of a server, or `nil` if none is set.
    def system_channel
      @bot.channel(@system_channel_id) if @system_channel_id
    end

    # Get the safety alerts channel of the server.
    # @return [Channel, nil] The channel where Community servers receive safety alerts from Discord, or `nil` if none is set.
    def safety_alerts_channel
      @bot.channel(@safety_alerts_channel_id) if @safety_alerts_channel_id
    end

    # Get the public updates channel of the server.
    # @return [Channel, nil] The channel where Community servers receive public updates from Discord, or `nil` if none is set.
    def public_updates_channel
      @bot.channel(@public_updates_channel_id) if @public_updates_channel_id
    end

    # Modify the properties of the server.
    # @param name [String] The new 2-32 character name of the server.
    # @param verification_level [Symbol, Integer, nil] The new verification level of the server.
    # @param notification_level [Symbol, Integer, nil] The new default message notification level of the server.
    # @param explicit_content_filter [Symbol, Integer, nil] The new explicit content filter level of the server.
    # @param afk_channel [Channel, Integer, String, nil] The new AFK voice channel members should be automatically moved to.
    # @param afk_timeout [Integer] The new AFK timeout in seconds. Can be set to one of `60`, `300`, `900`, `1800`, or `3600`.
    # @param icon [#read, File, nil] The new icon of the server. Should be a file-like object that responds to `#read`.
    # @param splash [#read, File, nil] The new invite splash of the server. Should be a file-like object that responds to `#read`.
    # @param discovery_splash [#read, File, nil] The new discovery splash of the server. Should be a file-like object that responds to `#read`.
    # @param banner [#read, File, nil] The new banner of the server. Should be a file-like object that responds to `#read`.
    # @param system_channel [Channel, Integer, String, nil] The new channel where system messages should be sent.
    # @param system_channel_flags [Integer] The new system channel flags to set for the server's system channel expressed as a bitfield.
    # @param rules_channel [Channel, Integer, String, nil] The new channel where the server displays its rules or guidelines.
    # @param public_updates_channel [Channel, Integer, String, nil] The new channel where public updates should be sent.
    # @param locale [String, Symbol, nil] The new preferred locale of the server; primarily for community servers.
    # @param features [Array<String, Symbol>] The new features to set for the server.
    # @param description [String, nil] The new description of the server.
    # @param boost_progress_bar [true, false] Whether or not the server boosting progress bar should be visible.
    # @param safety_alerts_channel [Channel, Integer, String, nil] The new channel where safety alerts should be sent.
    # @param dms_disabled_until [Time, nil] The time at when non-friend direct messages will be enabled again.
    # @param invites_disabled_until [Time, nil] The time at when invites will no longer be disabled.
    # @param reason [String, nil] The reason to show in the server's audit log for modifying the server.
    # @return [nil]
    def modify(
      name: :undef, verification_level: :undef, notification_level: :undef, explicit_content_filter: :undef,
      afk_channel: :undef, afk_timeout: :undef, icon: :undef, splash: :undef, discovery_splash: :undef, banner: :undef,
      system_channel: :undef, system_channel_flags: :undef, rules_channel: :undef, public_updates_channel: :undef,
      locale: :undef, features: :undef, description: :undef, boost_progress_bar: :undef, safety_alerts_channel: :undef,
      dms_disabled_until: :undef, invites_disabled_until: :undef, reason: nil
    )
      data = {
        name: name,
        verification_level: VERIFICATION_LEVELS[verification_level] || verification_level,
        default_message_notifications: NOTIFICATION_LEVELS[notification_level] || notification_level,
        explicit_content_filter: FILTER_LEVELS[explicit_content_filter] || explicit_content_filter,
        afk_channel_id: afk_channel == :undef ? afk_channel : afk_channel&.resolve_id,
        afk_timeout: afk_timeout,
        icon: icon.respond_to?(:read) ? Discordrb.encode64(icon) : icon,
        splash: splash.respond_to?(:read) ? Discordrb.encode64(splash) : splash,
        discovery_splash: discovery_splash.respond_to?(:read) ? Discordrb.encode64(discovery_splash) : discovery_splash,
        banner: banner.respond_to?(:read) ? Discordrb.encode64(banner) : banner,
        system_channel_id: system_channel == :undef ? system_channel : system_channel&.resolve_id,
        system_channel_flags: system_channel_flags,
        rules_channel_id: rules_channel == :undef ? rules_channel : rules_channel&.resolve_id,
        public_updates_channel_id: public_updates_channel == :undef ? public_updates_channel : public_updates_channel&.resolve_id,
        preferred_locale: locale,
        features: features == :undef ? features : features.map(&:upcase),
        description: description,
        premium_progress_bar_enabled: boost_progress_bar,
        safety_alerts_channel_id: safety_alerts_channel == :undef ? safety_alerts_channel : safety_alerts_channel&.resolve_id
      }

      if invites_disabled_until != :undef || dms_disabled_until != :undef
        incidents_data = {
          dms_disabled_until: dms_disabled_until == :undef ? @dms_disabled_until&.iso8601 : dms_disabled_until&.iso8601,
          invites_disabled_until: invites_disabled_until == :undef ? @invites_disabled_until&.iso8601 : invites_disabled_until&.iso8601
        }

        process_incident_actions(JSON.parse(API::Server.update_incident_actions(@bot.token, @id, **incidents_data, reason: reason)))
        return unless data.any? { |_, value| value != :undef }
      end

      update_data(JSON.parse(API::Server.update!(@bot.token, @id, **data, reason: reason)))
      nil
    end

    # Updates the cached data with new data
    # @note For internal use only
    # @!visibility private
    def update_data(new_data = nil)
      new_data ||= JSON.parse(API::Server.resolve(@bot.token, @id))
      @name = new_data['name']
      @icon_id = new_data['icon']
      @splash_id = new_data['splash']
      @discovery_splash_id = new_data['discovery_splash']
      @owner_id = new_data['owner_id'].to_i
      @region_id = new_data['region'] if new_data.key?('region')

      @afk_timeout = new_data['afk_timeout']
      @afk_channel_id = new_data['afk_channel_id']&.to_i

      @widget_enabled = new_data['widget_enabled'] if new_data.key?('widget_enabled')
      @widget_channel_id = new_data['widget_channel_id'] if new_data.key?('widget_channel_id')

      @system_channel_flags = new_data['system_channel_flags']
      @system_channel_id = new_data['system_channel_id']&.to_i

      @rules_channel_id = new_data['rules_channel_id']&.to_i
      @public_updates_channel_id = new_data['public_updates_channel_id']&.to_i
      @safety_alerts_channel_id = new_data['safety_alerts_channel_id']&.to_i

      @mfa_level = new_data['mfa_level']
      @nsfw_level = new_data['nsfw_level']
      @verification_level = new_data['verification_level']
      @explicit_content_filter = new_data['explicit_content_filter']
      @default_message_notifications = new_data['default_message_notifications']

      @features = new_data['features']&.map { |feature| feature.downcase.to_sym } || @features || []
      @max_presence_count = new_data['max_presences'] if new_data.key?('max_presences')
      @max_member_count = new_data['max_members'] if new_data.key?('max_members')
      @large = new_data.key?('large') ? new_data['large'] : (@large || false)
      @member_count = new_data['member_count'] || new_data['approximate_member_count'] || @member_count || 0

      @vanity_url_code = new_data['vanity_url_code']
      @description = new_data['description']
      @banner_id = new_data['banner']
      @boost_level = new_data['premium_tier']
      @booster_count = new_data['premium_subscription_count'] || @booster_count || 0
      @locale = new_data['preferred_locale']

      @max_video_channel_members = new_data['max_video_channel_users'] || @max_video_channel_members
      @max_stage_video_channel_members = new_data['max_stage_video_channel_users'] || @max_stage_video_channel_members
      @boost_progress_bar = new_data['premium_progress_bar_enabled']

      process_channels(new_data['channels']) if new_data['channels']
      process_roles(new_data['roles']) if new_data['roles']
      process_emoji(new_data['emojis']) if new_data['emojis']
      process_members(new_data['members']) if new_data['members']
      process_presences(new_data['presences']) if new_data['presences']
      process_voice_states(new_data['voice_states']) if new_data['voice_states']
      process_active_threads(new_data['threads']) if new_data['threads']
      process_incident_actions(new_data['incidents_data']) if new_data.key?('incidents_data')
      process_scheduled_events(new_data['guild_scheduled_events']) if new_data['guild_scheduled_events']
    end

    # Adds a channel to this server's cache
    # @note For internal use only
    # @!visibility private
    def add_channel(channel)
      @channels << channel
      @channels_by_id[channel.id] = channel
    end

    # Deletes a channel from this server's cache
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
      process_emoji(new_data['emojis'])
    end

    # Updates the threads for this server's cache
    # @note For internal use only
    # @!visibility private
    def clear_threads(ids = nil)
      if ids.nil?
        @channels.reject!(&:thread?)
        @channels_by_id.delete_if { |_, channel| channel.thread? }
      else
        @channels.reject! { |channel| channel.thread? && ids.any?(channel.parent&.id) }
        @channels_by_id.delete_if { |_, channel| channel.thread? && ids.any?(channel.parent&.id) }
      end
    end

    # The inspect method is overwritten to give more useful output
    def inspect
      "<Server name=#{@name} id=#{@id} large=#{@large} region=#{@region} owner=#{@owner} afk_channel_id=#{@afk_channel_id} system_channel_id=#{@system_channel_id} afk_timeout=#{@afk_timeout}>"
    end

    private

    def process_roles(roles)
      # Create roles
      @roles = {}

      return unless roles

      roles.each do |element|
        role = Role.new(element, @bot, self)
        @roles[role.id] = role
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
        next unless element['user']

        user_id = element['user']['id'].to_i
        user = @members[user_id]
        if user
          user.update_presence(element)
        else
          LOGGER.warn "Rogue presence update! #{element['user']['id']} on #{@id}"
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

    def process_active_threads(threads)
      @channels ||= []
      @channels_by_id ||= {}

      return unless threads

      threads.each do |element|
        thread = @bot.ensure_channel(element, self)
        @channels << thread
        @channels_by_id[thread.id] = thread
      end
    end

    def process_incident_actions(incidents)
      incidents ||= {}
      @raid_detected_at = incidents['raid_detected_at'] ? Time.parse(incidents['raid_detected_at']) : nil
      @dms_disabled_until = incidents['dms_disabled_until'] ? Time.parse(incidents['dms_disabled_until']) : nil
      @dm_spam_detected_at = incidents['dm_spam_detected_at'] ? Time.parse(incidents['dm_spam_detected_at']) : nil
      @invites_disabled_until = incidents['invites_disabled_until'] ? Time.parse(incidents['invites_disabled_until']) : nil
    end

    def process_scheduled_events(events)
      @scheduled_events = {}

      return unless events

      events.each do |element|
        event = ScheduledEvent.new(element, self, @bot)
        @scheduled_events[event.resolve_id] = event
      end
    end
  end

  # A ban entry on a server.
  class ServerBan
    # @return [String, nil] the reason the user was banned, if provided
    attr_reader :reason

    # @return [User] the user that was banned
    attr_reader :user

    # @return [Server] the server this ban belongs to
    attr_reader :server

    # @!visibility private
    def initialize(server, user, reason)
      @server = server
      @user = user
      @reason = reason
    end

    # Removes this ban on the associated user in the server
    # @param reason [String] the reason for removing the ban
    def remove(reason = nil)
      @server.unban(user, reason)
    end

    alias_method :unban, :remove
    alias_method :lift, :remove
  end

  # A bulk ban entry on a server.
  class BulkBan
    # @return [Server] The server this bulk ban belongs to.
    attr_reader :server

    # @return [String, nil] The reason these users were banned.
    attr_reader :reason

    # @return [Array<Integer>] Array of user IDs that were banned.
    attr_reader :banned_users

    # @return [Array<Integer>] Array of user IDs that couldn't be banned.
    attr_reader :failed_users

    # @!visibility private
    def initialize(data, server, reason)
      @server = server
      @reason = reason
      @banned_users = data['banned_users']&.map(&:resolve_id) || []
      @failed_users = data['failed_users']&.map(&:resolve_id) || []
    end
  end
end
