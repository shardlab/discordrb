# frozen_string_literal: true

module Discordrb
  # Basic attributes a server should have.
  module ServerAttributes
    # @return [String] the server's name.
    attr_reader :name

    # @return [String] the hexadecimal ID used to identify the server's icon.
    attr_reader :icon_id

    # Utility method to get a server's icon URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @param size [Integer, nil] The size of the image. You can specify any number from 0-4096 that's a power of two to override this.
    # @return [String, nil] The URL to the server's icon, or `nil` if the server doesn't have an icon set.
    def icon_url(format: 'webp', size: nil)
      API.icon_url(@id, @icon_id, format, size) if @icon_id
    end
  end

  # An isolated collection of channels and users on Discord.
  class Server
    include IDObject
    include ServerAttributes

    # Mapping of MFA levels.
    MFA_LEVELS = {
      none: 0,
      elevated: 1
    }.freeze

    # Mapping of NSFW levels.
    NSFW_LEVELS = {
      default: 0,
      explicit: 1,
      safe: 2,
      age_restricted: 3
    }.freeze

    # Mapping of verification levels.
    VERIFICATION_LEVELS = {
      none: 0,
      low: 1,
      medium: 2,
      high: 3,
      very_high: 4
    }.freeze

    # Mapping of default notification levels.
    NOTIFICATION_LEVELS = {
      all_messages: 0,
      only_mentions: 1
    }.freeze

    # Mapping of explicit content filter levels.
    FILTER_LEVELS = {
      disabled: 0,
      members_without_roles: 1,
      all_members: 2
    }.freeze

    # Mapping of system channel flags.
    SYSTEM_CHANNEL_FLAGS = {
      join_notifications: 1 << 0,
      boost_notifications: 1 << 1,
      reminder_notifications: 1 << 2,
      join_notification_replies: 1 << 3,
      role_subscription_notifications: 1 << 4,
      role_subscription_notification_replies: 1 << 5
    }.freeze

    # @deprecated Voice regions are now determined per-channel.
    attr_reader :region_id

    # @return [true, false] whether or not the server is large (members > 100). If it is,
    #   it means the members list may be inaccurate for a couple seconds after starting up the bot.
    attr_reader :large
    alias_method :large?, :large

    # @return [Array<Symbol>] the features of the server, e.g. `:guild_tags`, `:vanity_url`, etc.
    attr_reader :features

    # @return [Integer] the absolute number of members on the server, offline or not.
    attr_reader :member_count

    # @return [Integer] the amount of time after which a voice user gets moved into the AFK channel, in seconds.
    attr_reader :afk_timeout

    # @return [Hash<Integer => VoiceState>] a mapping of user IDs to voice states for each member on the server.
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

    # @return [Integer] the flags for the server's system channel. The flags indicate suppression. E.g. if
    #   the `join_notifications` flag is set in the bitfield, then `join_notifications` have been disabled.
    attr_reader :system_channel_flags

    # @return [Integer] the maximum number of members that can concurrently watch a stream in a voice channel.
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
      @emojis = {}
      @channels = {}
      @scheduled_events = {}
      @member_chunk_queries = {}
      @resolved_channels = data.key?('channels')

      # Whether the server's members have been chunked (resolved using op 8 and GUILD_MEMBERS_CHUNK) yet.
      @chunked = false

      update_data(data)
    end

    #  ##     ##    ###    #### ##    ##
    #  ###   ###   ## ##    ##  ###   ##
    #  #### ####  ##   ##   ##  ####  ##
    #  ## ### ## ##     ##  ##  ## ## ##
    #  ##     ## #########  ##  ##  ####
    #  ##     ## ##     ##  ##  ##   ###
    #  ##     ## ##     ## #### ##    ##

    # @!group General

    # Get the discoverable preview for the server.
    # @return [ServerPreview] The server's preview.
    def preview
      @bot.server_preview(@id)
    end

    # Get the webhooks for the server.
    # @return [Array<Webhook>] The webhooks for the server.
    def webhooks
      response = API::Server.webhooks(@bot.token, @id)
      JSON.parse(response).map { |element| Webhook.new(element, @bot) }
    end

    # Get the voice regions for the server.
    # @return [Array<VoiceRegion>] The voice regions for the server.
    def voice_regions
      return @voice_regions if @voice_regions

      response = JSON.parse(API::Server.regions(@bot.token, @id))
      @voice_regions = response.map { |element| VoiceRegion.new(element) }
    end

    # Get the integrations added to the server.
    # @return [Array<Integration>] The integrations for the server.
    # @note If the server has more than 50 integrations, they cannot be fetched.
    def integrations
      response = API::Server.integrations(@bot.token, @id)
      JSON.parse(response).map { |element| Integration.new(element, @bot, self) }
    end

    # Get a URL that will navigate to the server in the Discord client when clicked.
    # @return [String] A link that will navigate to the server in the Discord client.
    def link
      "https://discord.com/channels/#{@id}"
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
    # @param system_channel_flags [Integer, Symbol, Array<Integer, Symbol>] The new system channel flags to set for the server's system channel.
    # @param rules_channel [Channel, Integer, String, nil] The new channel where the server displays its rules or guidelines.
    # @param public_updates_channel [Channel, Integer, String, nil] The new channel where public updates should be sent.
    # @param locale [String, Symbol, nil] The new preferred locale of the server; primarily for community servers.
    # @param features [Array<String, Symbol>] The new features to set for the server.
    # @param description [String, nil] The new description of the server.
    # @param boost_progress_bar [true, false] Whether or not the server boosting progress bar should be visible.
    # @param safety_alerts_channel [Channel, Integer, String, nil] The new channel where safety alerts should be sent.
    # @param widget_enabled [true, false, nil] Whether or not the server's widget should be enabled.
    # @param widget_channel [Channel, Integer, String, nil] The new invite channel for the server's widget.
    # @param dms_disabled_until [Time, nil] The time at when non-friend direct messages will be enabled again.
    # @param invites_disabled_until [Time, nil] The time at when invites will no longer be disabled.
    # @param reason [String, nil] The reason to show in the server's audit log for modifying the server.
    # @return [nil]
    def modify(
      name: :undef, verification_level: :undef, notification_level: :undef, explicit_content_filter: :undef,
      afk_channel: :undef, afk_timeout: :undef, icon: :undef, splash: :undef, discovery_splash: :undef, banner: :undef,
      system_channel: :undef, system_channel_flags: :undef, rules_channel: :undef, public_updates_channel: :undef,
      locale: :undef, features: :undef, description: :undef, boost_progress_bar: :undef, safety_alerts_channel: :undef,
      widget_enabled: :undef, widget_channel: :undef, dms_disabled_until: :undef, invites_disabled_until: :undef,
      reason: nil
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
        system_channel_flags: system_channel_flags == :undef ? system_channel_flags : [*system_channel_flags].reduce(0) { |sum, flag| sum | (SYSTEM_CHANNEL_FLAGS[flag] || flag) },
        rules_channel_id: rules_channel == :undef ? rules_channel : rules_channel&.resolve_id,
        public_updates_channel_id: public_updates_channel == :undef ? public_updates_channel : public_updates_channel&.resolve_id,
        preferred_locale: locale,
        features: features == :undef ? features : features.map(&:upcase),
        description: description,
        premium_progress_bar_enabled: boost_progress_bar,
        safety_alerts_channel_id: safety_alerts_channel == :undef ? safety_alerts_channel : safety_alerts_channel&.resolve_id
      }

      if widget_enabled != :undef || widget_channel != :undef
        widget_data = {
          enabled: widget_enabled,
          channel_id: widget_channel == :undef ? widget_channel : widget_channel&.resolve_id
        }

        cache_widget(JSON.parse(API::Server.update_widget(@bot.token, @id, **widget_data, reason: reason)))
      end

      if invites_disabled_until != :undef || dms_disabled_until != :undef
        incidents_data = {
          dms_disabled_until: dms_disabled_until == :undef ? @dms_disabled_until&.iso8601 : dms_disabled_until&.iso8601,
          invites_disabled_until: invites_disabled_until == :undef ? @invites_disabled_until&.iso8601 : invites_disabled_until&.iso8601
        }

        # rubocop:disable Style/IfUnlessModifier
        if (dms_disabled_until == :undef) && @dms_disabled_until && (@dms_disabled_until <= Time.now)
          incidents_data[:dms_disabled_until] = :undef
        end

        if (invites_disabled_until == :undef) && @invites_disabled_until && (@invites_disabled_until <= Time.now)
          incidents_data[:invites_disabled_until] = :undef
        end

        # rubocop:enable Style/IfUnlessModifier
        process_incident_actions(JSON.parse(API::Server.update_incident_actions(@bot.token, @id, **incidents_data, reason: reason)))
      end

      return unless data.any? { |_, value| value != :undef }

      update_data(JSON.parse(API::Server.update!(@bot.token, @id, **data, reason: reason)))
      nil
    end

    alias_method :jump_link, :link
    alias_method :available_voice_regions, :voice_regions

    # @!endgroup

    #  ##       ######## ##     ## ######## ##        ######
    #  ##       ##       ##     ## ##       ##       ##    ##
    #  ##       ##       ##     ## ##       ##       ##
    #  ##       ######   ##     ## ######   ##        ######
    #  ##       ##        ##   ##  ##       ##             ##
    #  ##       ##         ## ##   ##       ##       ##    ##
    #  ######## ########    ###    ######## ########  ######

    # @!group Levels

    # Get the MFA level for the server.
    # @return [Symbol] The MFA level for the server.
    # @see MFA_LEVELS
    def mfa_level
      MFA_LEVELS.key(@mfa_level)
    end

    # Get the NSFW level for the server.
    # @return [Symbol] The NSFW level for the server.
    # @see NSFW_LEVELS
    def nsfw_level
      NSFW_LEVELS.key(@nsfw_level)
    end

    # Get the content filter level for the server.
    # @return [Symbol] The filter level for the server.
    # @see FILTER_LEVELS
    def explicit_content_filter
      FILTER_LEVELS.key(@explicit_content_filter)
    end

    # Get the verification level for the server.
    # @return [Symbol] The verification level for the server.
    # @see VERIFICATION_LEVELS
    def verification_level
      VERIFICATION_LEVELS.key(@verification_level)
    end

    # Get the default notification level for the server.
    # @return [Symbol] The default notification level for the server.
    # @see NOTIFICATION_LEVELS
    def notification_level
      NOTIFICATION_LEVELS.key(@notification_level)
    end

    alias_method :default_message_notifications, :notification_level
    alias_method :explicit_content_filter_level, :explicit_content_filter

    # @!endgroup

    #     ###     ######   ######  ######## ########  ######
    #    ## ##   ##    ## ##    ## ##          ##    ##    ##
    #   ##   ##  ##       ##       ##          ##    ##
    #  ##     ##  ######   ######  ######      ##     ######
    #  #########       ##       ## ##          ##          ##
    #  ##     ## ##    ## ##    ## ##          ##    ##    ##
    #  ##     ##  ######   ######  ########    ##     ######

    # @!group Assets

    # Utility method to get a server's splash URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @param size [Integer, nil] The size of the image. You can specify any number from 0-4096 that's a power of two to override this.
    # @return [String, nil] The URL to the server's splash image, or `nil` if the server doesn't have a splash image.
    def splash_url(format: 'webp', size: nil)
      API.splash_url(@id, @splash_id, format, size) if @splash_id
    end

    # Utility method to get a server's banner URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @param size [Integer, nil] The size of the image. You can specify any number from 0-4096 that's a power of two to override this.
    # @return [String, nil] The URL to the server's banner image, or `nil` if the server doesn't have a banner image.
    def banner_url(format: 'webp', size: nil)
      API.banner_url(@id, @banner_id, format, size) if @banner_id
    end

    # Utility method to get a server's discovery splash URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @param size [Integer, nil] The size of the image. You can specify any number from 0-4096 that's a power of two to override this.
    # @return [String, nil] The URL to the server's discovery splash image, or `nil` if the server doesn't have a discovery splash image.
    def discovery_splash_url(format: 'webp', size: nil)
      API.discovery_splash_url(@id, @discovery_splash_id, format, size) if @discovery_splash_id
    end

    # @!endgroup

    #  ######   #######  ##       ########  ######
    #  ##   ## ##     ## ##       ##       ##
    #  ##   ## ##     ## ##       ##       ##
    #  ######  ##     ## ##       ######    ######
    #  ## ##   ##     ## ##       ##             ##
    #  ##  ##  ##     ## ##       ##             ##
    #  ##   ##  #######  ######## ######## ######

    # @!group Roles

    # Get the default role for the server.
    # @return [Role] The `@everyone` role for the server.
    def everyone_role
      @roles[@id]
    end

    # Get the roles for the server.
    # @param bypass_cache [true, false] Whether the cached roles should be
    #   ignored and re-fetched via an HTTP request.
    # @return [Array<Role>] The roles for the server.
    def roles(bypass_cache: false)
      process_roles(JSON.parse(API::Server.roles(@bot.token, @id))) if bypass_cache

      @roles.values
    end

    # Get a role from the server via its ID.
    # @param id [String, Integer] The ID of the role that should be resolved.
    # @param request [true, false] Whether to request the role if it isn't cached.
    # @return [Role, nil] The role identified by its ID, or `nil` if it couldn't be found.
    def role(id, request: false)
      id = id.resolve_id
      cached = @roles[id]
      return cached if cached || !request

      data = JSON.parse(API::Server.role(@bot.token, @id, id))
      Role.new(data, @bot, self).tap { |role| cache_role(role) }
    rescue StandardError
      nil
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

    # Create a new role.
    # @param name [String, nil] The name of the role; between 1-100 characters.
    # @param unicode_emoji [String, nil] The standard unicode emoji to set for the role's icon.
    # @param display_icon [String, #read, nil] The custom icon or unicode emoji to set for the role.
    # @param permissions [Permissions, Integer, String, nil] The permissions to set for the role.
    # @param icon [File, #read, nil] The custom icon to set for the role. Must be a file-like object.
    # @param hoist [true, false, nil] Whether or not the role should be shown separately in the member's list.
    # @param mentionable [true, false, nil] Whether or not any server member can mention the role in messages.
    # @param colour [Integer, ColourRGB, #combined, nil] The primary colour to set for the role.
    # @param tertiary_colour [Integer, ColourRGB, nil] The tertiary colour to set for the role.
    # @param secondary_colour [Integer, ColourRGB, nil] The secondary colour to set for the role.
    # @param reason [String, nil] the reason to show in the server's audit log for creating the role.
    # @note The `display_icon` parameter will overwrite the `icon` and `unicode_emoji` parameters.
    # @note The American spelling can be used instead of the British spelling for all of the colour parameters.
    # @return [Role] the newly created role on the server.
    def create_role(
      name: nil, hoist: nil, mentionable: nil, icon: nil, unicode_emoji: nil, display_icon: nil,
      colour: nil, color: nil, secondary_colour: nil, secondary_color: nil, tertiary_colour: nil,
      tertiary_color: nil, permissions: 104_324_161, reason: nil
    )
      if display_icon.respond_to?(:read)
        icon = display_icon
        unicode_emoji = :undef
      elsif display_icon.is_a?(String)
        icon = :undef
        unicode_emoji = display_icon
      end

      permissions = if permissions.is_a?(Array)
                      Permissions.bits(permissions)
                    elsif permissions.respond_to?(:bits)
                      permissions.bits
                    else
                      permissions
                    end

      # For backwards compatability.
      (colour = colour.combined) if colour.respond_to?(:combined)

      data = {
        name: name&.to_s || 'new role',
        permissions: permissions&.to_s || :undef,
        icon: icon.respond_to?(:read) ? Discordrb.encode64(icon) : (icon || :undef),
        unicode_emoji: unicode_emoji || :undef,
        hoist: hoist.nil? ? :undef : hoist,
        mentionable: mentionable.nil? ? :undef : mentionable,
        colors: {
          primary_color: (colour || color || 0).to_i,
          tertiary_color: (tertiary_colour || tertiary_color)&.to_i,
          secondary_color: (secondary_colour || secondary_color)&.to_i
        }
      }

      data = API::Server.create_role!(@bot.token, @id, **data, reason:)
      Role.new(JSON.parse(data), @bot, self).tap { |role| cache_role(role) }
    end

    # @!endgroup

    #  ##     ## ######## ##     ## ########  ######## ########   ######
    #  ###   ### ##       ###   ### ##     #  ##       ##     ## ##    ##
    #  #### #### ##       #### #### ##     #  ##       ##     ## ##
    #  ## ### ## ######   ## ### ## #######   ######   ########   ######
    #  ##     ## ##       ##     ## ##     #  ##       ##   ##         ##
    #  ##     ## ##       ##     ## ##     #  ##       ##    ##  ##    ##
    #  ##     ## ######## ##     ## ########  ######## ##     ##  ######

    # @!group Members

    # Get the member who owns the server.
    # @return [Member] The member who owns the server.
    def owner
      member(@owner_id)
    end

    # Get the bot's own member on the server.
    # @return [Member] The member for the current bot.
    def bot
      member(@bot.profile)
    end

    # Get the bot accounts that are in the server.
    # @return [Array<Member>] An array of all the bot accounts on the server.
    def bot_members
      members.select(&:bot_account?)
    end

    # Get the user accounts that are in the server.
    # @return [Array<Member>] An array of all the user accounts on the server.
    def non_bot_members
      members.reject(&:bot_account?)
    end

    # Make the current bot leave the server. Use this with caution.
    # @note In a future release, the return type of this method will be changed to `nil`.
    # @return [void]
    def leave
      API::User.leave_server(@bot.token, @id)
    end

    # Get a single member in the server by their user ID.
    # @param user_id [Integer, String, User] The user ID of the member to fetch.
    # @param request [true, false, nil] Whether to fetch the member if it isn't cached.
    # @return [Member, nil] The member for the given user ID, or `nil` if it couldn't be found.
    def member(user_id, request = true)
      id = user_id.resolve_id
      cached = @members[id]
      return cached if cached || !request

      @bot.member(self, id)
    rescue StandardError
      nil
    end

    # Kick a member from the server.
    # @param id [User, Member, String, Integer] The member to kick.
    # @param reason [String, nil] The reason to show in the server's audit log for kicking the member.
    # @return [nil]
    def kick!(id, reason: nil)
      API::Server.remove_member(@bot.token, @id, id.resolve_id, reason)
      nil
    end

    # Get the members that currently have an "online" presence.
    # @param include_idle [true, false] Whether to count idle members as online.
    # @param include_bots [true, false] Whether to include bot accounts in the count.
    # @return [Array<Member>] An array of online members on the server.
    def online_members(include_idle: false, include_bots: true)
      members.select do |user|
        ((include_idle ? user.idle? : false) || user.online?) && (include_bots ? true : !user.bot_account?)
      end
    end

    # Adds a member to the server that has granted the bot an OAuth2 access token with the `guilds.join` scope.
    #   For more information, see: https://discord.com/developers/docs/topics/oauth2.
    # @param user [User, String, Integer] The user, or the ID of the user to add to the server.
    # @param access_token [String] The OAuth2 Bearer token that has been granted the `guilds.join` scope.
    # @param nick [String, nil] The nickname to give the member upon joining.
    # @param roles [Role, Array<Role, String, Integer>] The role (or roles) to give the member upon joining.
    # @param mute [true, false] Whether the member should be server muted upon joining.
    # @param deaf [true, false] Whether the member should be server deafened upon joining.
    # @param flags [Integer] The flags to set for the member upon joining.
    # @note Your bot must be present in the server, and have permission to create instant invites.
    # @return [Member, nil] The member that was added, or `nil` if the user is already a server member.
    def add_member_using_token(user, access_token, nick: nil, roles: [], deaf: false, mute: false, flags: 0)
      roles = roles.is_a?(Enumerable) ? roles.map(&:resolve_id) : [roles.resolve_id]
      response = API::Server.add_member(@bot.token, @id, user.resolve_id, access_token, nick, roles, deaf, mute, flags)
      response.empty? ? nil : cache_member(Member.new(JSON.parse(response), self, @bot), increment: @bot.gateway.intents.nobits?(INTENTS[:server_members]))
    end

    # Get a list of all of the members that are in the server.
    # @return [Array<Member>] An array of all of the members that are in the server.
    # @raise [RuntimeError] If the bot was created without the `:server_members` intent.
    def members
      return @members.values if @chunked

      @bot.debug("Members for server #{@id} not chunked yet - initiating")

      # If the SERVER_MEMBERS intent isn't set, the gateway won't respond when we ask for members.
      raise 'The :server_members intent is required to get server members' if @bot.gateway.intents.nobits?(INTENTS[:server_members])

      @bot.request_chunks(@id)
      sleep(0.01) until @chunked
      @members.values
    end

    # Query the members in the server.
    # @param name [String, nil] Get members with matching usernames or nicknames.
    # @param limit [Integer, nil] The maximum number of members to fetch; between 1-1000.
    # @param ids [Array, Set, #resolve_id, nil] Get members for these user IDs; between 1-100.
    # @return [QueriedMembers] The resulting server member data for the query that was executed.
    # @note the `name:` and `ids:` parameters are mutually exclusive. At least one must be passed.
    #   `limit:` cannot be used in conjunction with the `ids:` parameter.
    def query_members(name: nil, limit: nil, ids: nil)
      # rubocop:disable Style/IfUnlessModifier
      if name && ids
        raise ArgumentError, "'name' and 'ids' are mutually exclusive"
      end

      if !name && !ids
        raise ArgumentError, "One of 'name' or 'ids' must be provided"
      end

      if ids && limit
        raise ArgumentError, "'limit' cannot be used in conjunction with 'ids'"
      end

      if name && !((limit ||= 100).between?(1, 1000))
        raise ArgumentError, "'limit' must be between 1-1000 when using 'name'"
      end

      if ids && !((ids = Array(ids)).length.between?(1, 100))
        raise ArgumentError, "the length of 'ids' must be between 1-100 elements"
      end

      # rubocop:enable Style/IfUnlessModifier
      if name
        data = API::Server.search_guild_members(@bot.token, @id, name, limit)

        return QueriedMembers.new({ members: JSON.parse(data) }, self, @bot)
      end

      time = Time.now + 70

      nonce = SecureRandom.urlsafe_base64(24)

      @member_chunk_queries[nonce] = nil

      @bot.gateway.send_request_members(@id, nil, nil, nonce, ids.map(&:resolve_id))

      sleep(0.01) until (@member_chunk_queries[nonce]) || (Time.now > time)

      QueriedMembers.new(@member_chunk_queries.delete(nonce) || { timeout: true }, self, @bot)
    end

    alias_method :users, :members
    alias_method :online_users, :online_members

    # @!endgroup

    #  ######   ##     ##    ###    ##    ## ##    ## ######## ##        ######
    #  ##    ## ##     ##   ## ##   ###   ## ###   ## ##       ##       ##    ##
    #  ##       ##     ##  ##   ##  ####  ## ####  ## ##       ##       ##
    #  ##       ######### ##     ## ## ## ## ## ## ## ######   ##        ######
    #  ##       ##     ## ######### ##  #### ##  #### ##       ##             ##
    #  ##    ## ##     ## ##     ## ##   ### ##   ### ##       ##       ##    ##
    #  ######   ##     ## ##     ## ##    ## ##    ## ######## ########  ######

    # @!group Channels

    # Get the AFK channel of the server.
    # @return [Channel, nil] the AFK voice channel of the server, or `nil` if none is set.
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

    # Get a list of the category channels on the server.
    # @return [Array<Channel>] A list of the category channels on the server.
    def categories
      @channels.filter_map { |_, channel| channel if channel.category? }
    end

    # Get the channels in the server that are not in a category.
    # @return [Array<Channel>] An array of channels that are not in a category.
    def orphan_channels
      @channels.filter_map { |_, channel| channel unless channel.parent || channel.category? }
    end

    # Get the channels for the server.
    # @param bypass_cache [true, false] Whether the cached channels should be
    #   ignored and re-fetched via an HTTP request.
    # @return [Array<Channel>] The channels for the server.
    def channels(bypass_cache: false)
      if bypass_cache || !@resolved_channels
        process_channels(JSON.parse(API::Server.channels(@bot.token, @id)))

        data = JSON.parse(API::Server.list_active_threads(@bot.token, @id))

        data['members'].each do |member|
          thread = data['threads'].find { |item| item['id'] == member['id'] }

          (thread['member'] = member) if member
        end

        @resolved_channels = true

        process_active_threads(data['threads'])
      end

      @channels.values
    end

    # Create a new channel.
    # @param name [String] The name of the channel; between 1-100 characters.
    # @param type [Symbol, Integer, nil] The type of the channel; see {Channel::TYPES}.
    # @param topic [String, nil] The topic of the channel; between 1-4096 characters.
    # @param nsfw [true, false, nil] Whether or not to mark the channel as age-restricted.
    # @param rate_limit_per_user [Integer, nil] The slowmode-rate of the channel; between 0-21600 (in seconds).
    # @param bitrate [Integer, nil] The bitrate of the voice or stage channel; minimum of 8000 (in bits).
    # @param user_limit [Integer, nil] The maximum number of users who can join the voice or stage channel; 0 for no limit.
    # @param permission_overwrites [Array<Hash, Overwrite>, nil] The permission overwrite to apply to the channel.
    # @param parent [Channel, Integer, String, nil] The category to create the channel under, or `nil` to orphan the channel.
    # @param voice_region [VoiceRegion, String, Symbol, nil] The RTC voice region of the stage or voice channel.
    # @param video_quality_mode [Symbol, Integer, nil] The camera video quality mode of the voice or stage channel.
    # @param default_auto_archive_duration [60, 1440, 4320, 10080, nil] The duration (in seconds) before threads created in the channel are hidden.
    # @param tags [Array<ChannelTag, #to_h>, nil] The tags that should be available in the forum channel.
    # @param default_reaction [Integer, String, Emoji, nil] The emoji to display on threads created in the forum channel.
    # @param default_sort_order [Integer, Symbol, nil] The default order used to order threads in the forum channel.
    # @param position [Integer, nil] The sorting position of the channel. Using this parameter is highly discouraged.
    # @param default_forum_layout [Integer, Symbol, nil] The default layout type used to display threads in the forum channel.
    # @param default_thread_rate_limit_per_user [Integer, nil] The default slowmode rate to set on threads created in the text or forum channel.
    # @param reason [String, nil] The reason to show in the server's audit log for creating the channel.
    # @raise [ArgumentError] If the `type:` argument is an invalid channel type.
    # @return [Channel] The channel that was created.
    def create_channel!(
      name:, type:, topic: nil, nsfw: nil, rate_limit_per_user: nil,
      bitrate: nil, user_limit: nil, permission_overwrites: nil, parent: nil,
      voice_region: nil, video_quality_mode: nil, default_auto_archive_duration: nil,
      tags: nil, default_reaction: nil, default_sort_order: nil, position: nil,
      default_forum_layout: nil, default_thread_rate_limit_per_user: nil, reason: nil
    )
      data = {
        name: name,
        type: Channel::TYPES[type] || type,
        topic: topic,
        nsfw: nsfw,
        position: position,
        rate_limit_per_user: rate_limit_per_user,
        bitrate: bitrate,
        user_limit: user_limit,
        permission_overwrites: permission_overwrites&.map(&:to_hash),
        parent_id: parent&.resolve_id,
        rtc_region: voice_region&.to_s,
        video_quality_mode: Channel::VIDEO_QUALITY_MODES[video_quality_mode] || video_quality_mode,
        default_auto_archive_duration: default_auto_archive_duration,
        default_reaction_emoji: default_reaction ? Emoji.build_emoji_hash(default_reaction) : nil,
        default_sort_order: Channel::FORUM_SORT_ORDERS[default_sort_order] || default_sort_order,
        default_forum_layout: Channel::FORUM_LAYOUTS[default_forum_layout] || default_forum_layout,
        default_thread_rate_limit_per_user: default_thread_rate_limit_per_user,
        available_tags: tags ? Array(tags).map(&:to_h) : tags,
        reason: reason
      }

      raise ArgumentError, 'Invalid channel type' if [1, 3, 6, 10, 11, 12, 14].any?(data[:type])

      @bot.ensure_channel(JSON.parse(API::Channel.create!(@bot.token, @id, **data.compact)), self)
    end

    # Search the messages that have been sent in the server.
    # @example Search for 200 messages from a user that contain an attachment.
    #  options = {
    #    limit: 200,
    #    contains: :file,
    #    authors: 171764626755813376
    #  }
    #
    #  results = server.search_messages(**options)
    # @example Search for all of the messages in a channel that mentions someone.
    #  options = {
    #    limit: nil,
    #    mentions: 171764626755813376,
    #    channels: 381891448884428801
    #  }
    #
    #  results = server.search_messages(**options)
    # @example Search for 105 messages that contain specific embed types, sorted by oldest to newest.
    #  options = {
    #    limit: 105,
    #    embed_types: %i[article image],
    #    sort_order: :ascending
    #  }
    #
    #  results = server.search_messages(**options)
    # @example Search for 30 messages sent between two dates that contain the word “time” and an @everyone ping.
    #  options = {
    #    limit: 30,
    #    content: 'time',
    #    mentions_everyone: true,
    #    after: Time.parse("December 16th, 2020"),
    #    before: Time.parse("December 25th, 2020")
    #  }
    #
    #  results = server.search_messages(**options)
    # @example Search for 500 messages that reply to a specific message, contain a Ruby file, and were sent by a bot account.
    #  options = {
    #    limit: 500,
    #    author_types: :bot,
    #    file_extensions: '.rb',
    #    reply_messages: 1454184993923268660
    #  }
    #
    #  results = server.search_messages(**options)
    # @param limit [Integer, nil] The maximum number of messages to return, or `nil` to fetch all of the messages that match the search query.
    # @param offset [Integer, nil] The number of messages between 0-9975 to offset the search query by.
    # @param before [Time, #resolve_id, nil] Get messages sent before this timestamp.
    # @param after [Time, #resolve_id, nil] Get messages sent after this timestamp.
    # @param content [String, #to_s, nil] Get messages with matching message content.
    # @param slop [Integer, nil] The amount of variation allowed between the placement of words when matching against message content; between 0-100.
    # @param channels [Array<Channel, Integer, String>, Channel, Integer, String, nil] Get messages that were sent in these channels.
    # @param authors [Array<#resolve_id>, #resolve_id, nil] Get messages that were created by these authors.
    # @param author_types [Array<String, Symbol>, String, Symbol, nil] Get messages that were created by these author types: `user`, `bot`, or `webhook`.
    # @param mentions [Array<#resolve_id>, #resolve_id, nil] Get messages that mention these users or members.
    # @param role_mentions [Array<Role, Integer, String>, Role, Integer, String, nil] Get messages that mention these roles.
    # @param mentions_everyone [true, false, nil] Get messages that mention the @everyone role.
    # @param reply_users [Array<#resolve_id>, #resolve_id, nil] Get messages that replied to these users or members.
    # @param reply_messages [Array<Message, Integer, String>, Message, Integer, String, nil] Get messages that replied to these messages.
    # @param pinned [true, false, nil] Get messages that are pinned.
    # @param contains [Array<String, Symbol>, String, Symbol, nil] Get messages that contain specific fields, e.g. `file`, `poll`, `sound`, etc.
    # @param embed_types [Array<String, Symbol>, String, Symbol, nil] Get messages that contain matching embed types.
    # @param embed_providers [Array<String, Symbol>, String, Symbol, nil] Get messages that contain embeds from specific providers.
    # @param link_hosts [Array<String, Symbol>, String, Symbol, nil] Get messages that contain matching link hostnames, e.g. `discord.com`.
    # @param file_names [Array<String, Symbol, Attachment>, String, Symbol, Attachment, nil] Get messages that contain matching attachment filenames.
    # @param file_extensions [Array<String, Symbol>, String, Symbol, nil] Get messages that contain matching attachment file extensions, e.g. `.rb`, `.mp3`, etc.
    # @param include_nsfw [true, false, nil] Whether or not to include messages that have been sent in NSFW channels.
    # @param sort_by [Symbol, String, nil] Whether to sort the returned messages by their `:creation_time`, or `:relevance` to the search query.
    # @param sort_order [Symbol, string, nil] Whether to order the returned messages in `:descending`, or `:ascending` order. Not respected when sorting by `:relevance`.
    # @raise [Discordrb::Errors::NoPermission] This may occur when the application has not enabled the `MESSAGE_CONTENT` privileged intent on the Discord Developer Portal.
    # @note Messages with GIFs sent before February 24th, 2026 may not be returned under the `gif` embed type when using the `embed_types:` parameter.
    # @note Messages fetched via this method will not contain reactions. This means that {Message#reactions} will **always** return an empty array, even if the message has reactions.
    # @return [SearchedMessages] the results of the search query.
    def search_messages(
      limit: 25, offset: nil, before: nil, after: nil, content: nil, slop: 2, channels: nil, authors: nil, author_types: nil,
      mentions: nil, role_mentions: nil, mentions_everyone: nil, reply_users: nil, reply_messages: nil, pinned: nil, contains: nil,
      embed_types: nil, embed_providers: nil, link_hosts: nil, file_names: nil, file_extensions: nil, include_nsfw: true, sort_by: nil,
      sort_order: :descending
    )
      sort_order = case sort_order&.to_sym
                   when nil, :desc, :descending, :newest_first
                     :desc
                   when :asc, :ascending, :oldest_first
                     :asc
                   else
                     raise ArgumentError, "Invalid value for the 'sort_order' parameter"
                   end

      sort_by = case sort_by&.to_sym
                when nil, :timestamp, :creation_time
                  :timestamp
                when :relevance, :match_score
                  :relevance
                else
                  raise ArgumentError, "Invalid value for the 'sort_by' parameter"
                end

      options = {
        limit: limit && limit <= 25 ? limit : 25,
        max_id: before.is_a?(Time) ? IDObject.synthesise(before) : before&.resolve_id,
        min_id: after.is_a?(Time) ? IDObject.synthesise(after) : after&.resolve_id,
        offset: offset || 0,
        slop: slop,
        content: content&.to_s,
        channel_id: channels ? Array(channels).map(&:resolve_id) : channels,
        author_type: author_types ? Array(author_types) : author_types,
        author_id: authors ? Array(authors).map(&:resolve_id) : authors,
        mentions: mentions ? Array(mentions).map(&:resolve_id) : mentions,
        mentions_role_id: role_mentions ? Array(role_mentions).map(&:resolve_id) : role_mentions,
        mention_everyone: mentions_everyone,
        replied_to_user_id: reply_users ? Array(reply_users).map(&:resolve_id) : reply_users,
        replied_to_message_id: reply_messages ? Array(reply_messages).map(&:resolve_id) : reply_messages,
        pinned: pinned,
        has: contains ? Array(contains) : contains,
        embed_type: embed_types ? Array(embed_types) : embed_types,
        embed_provider: embed_providers ? Array(embed_providers) : embed_providers,
        link_hostname: link_hosts ? Array(link_hosts) : link_hosts,
        attachment_filename: (Array(file_names).map { |file| file.is_a?(Attachment) ? file.filename : file } if file_names),
        attachment_extension: file_extensions ? Array(file_extensions).map { |type| type.to_s.delete_prefix('.') } : file_extensions,
        sort_by: sort_by,
        sort_order: sort_order,
        include_nsfw: include_nsfw
      }.compact

      raise ArgumentError, "The 'role_mentions' parameter cannot contain the everyone role" if options[:mentions_role_id]&.any?(@id)

      # Only store the total message count from the first request.
      total = nil

      get_messages = lambda do |query|
        data = JSON.parse(API::Server.search_messages(@bot.token, @id, **options, **query.compact))
        total ||= data['total_results']

        data['threads']&.each do |thread|
          thread['member'] = data['members']&.find { |member| thread['id'] == member['id'] }

          @bot.ensure_channel(thread, self)
        end

        data['messages'].collect { |nested_messages| Message.new(nested_messages[0], @bot) }
      end

      paginator = Paginator.new(limit, :down) do |page|
        if sort_by == :relevance
          if (count = (paginator.amount_fetched + options[:offset])) > 9975
            []
          else
            get_messages.call(offset: count)
          end
        elsif sort_order == :desc
          get_messages.call(max_id: page&.last&.id, offset: page ? 0 : nil)
        else
          get_messages.call(min_id: page&.last&.id, offset: page ? 0 : nil)
        end
      end

      SearchedMessages.new(paginator.to_a, total, @bot)
    end

    # @!endgroup

    #   ######  ##    ##  ######  ######## ######## ##     ##      ######## ##          ###     ######    ######
    #  ##    ##  ##  ##  ##    ##    ##    ##       ###   ###      ##       ##         ## ##   ##    ##  ##    ##
    #  ##         ####   ##          ##    ##       #### ####      ##       ##        ##   ##  ##        ##
    #   ######     ##     ######     ##    ######   ## ### ##      ######   ##       ##     ## ##   ####  ######
    #        ##    ##          ##    ##    ##       ##     ##      ##       ##       ######### ##    ##        ##
    #  ##    ##    ##    ##    ##    ##    ##       ##     ##      ##       ##       ##     ## ##    ##  ##    ##
    #   ######     ##     ######     ##    ######## ##     ##      ##       ######## ##     ##  ######    ######

    # @!group System Channel Notifications

    # @!method join_notifications?
    #   @return [true, false] whether or not the server has enabled member join notifications.
    # @!method boost_notifications?
    #   @return [true, false] whether or not the server has enabled server boost notifications.
    # @!method reminder_notifications?
    #   @return [true, false] whether or not the server has enabled server setup tips.
    # @!method join_notification_replies?
    #   @return [true, false] whether or not the server has enabled the member join sticker reply buttons.
    # @!method role_subscription_notifications?
    #   @return [true, false] whether or not the server has enabled role subscription purchase notifications.
    # @!method role_subscription_notification_replies?
    #   @return [true, false] whether or not the server has enabled the role subscription purchase sticker reply buttons.
    SYSTEM_CHANNEL_FLAGS.each do |name, value|
      define_method("#{name}?") do
        @system_channel_id ? @system_channel_flags.nobits?(value) : false
      end
    end

    # @!endgroup

    #  ######## ##     ##  #######        ## ####  ######
    #  ##       ###   ### ##     ##       ##  ##  ##    ##
    #  ##       #### #### ##     ##       ##  ##  ##
    #  ######   ## ### ## ##     ##       ##  ##   ######
    #  ##       ##     ## ##     ## ##    ##  ##        ##
    #  ##       ##     ## ##     ## ##    ##  ##  ##    ##
    #  ######## ##     ##  #######   ######  ####  ######

    # @!group Emojis

    # Get the emojis for the server.
    # @param bypass_cache [true, false] Whether the cached emojis should be
    #   ignored and re-fetched via an HTTP request.
    # @return [Hash<Integer => Emoji>] A hash mapping emoji IDs to emoji objects.
    def emojis(bypass_cache: false)
      process_emojis(JSON.parse(API::Server.list_emojis(@bot.token, @id))) if bypass_cache

      @emojis
    end

    # Create a new emoji.
    # @param name [String] The 2-32 character name of the emoji.
    # @param file [File, #read] A file-like object that responds to `#read`.
    # @param roles [Array<Role, Integer, String>, nil] The roles that are allowed to use the emoji.
    # @param reason [String, nil] The reason to show in the server's audit log for creating the emoji.
    # @return [Emoji] The emoji that was created.
    def create_emoji(name:, file:, roles: nil, reason: nil)
      data = {
        name: name.to_s,
        roles: roles ? Array(roles).map(&:resolve_id) : :undef,
        image: file.respond_to?(:read) ? Discordrb.encode64(file) : file
      }

      data = API::Server.create_emoji(@bot.token, @id, **data, reason: reason)
      Emoji.new(JSON.parse(data), @bot, self).tap { |emoji| cache_emoji(emoji) }
    end

    alias_method :emoji, :emojis

    # @!endgroup

    #  ##     ##    ## #### ########   ######   ######## ########
    #  ##     ##    ##  ##  ##     ## ##    ##  ##          ##
    #  ##     ##    ##  ##  ##     ## ##        ##          ##
    #  ##     ##    ##  ##  ##     ## ##   #### ######      ##
    #  ##    ####   ##  ##  ##     ## ##    ##  ##          ##
    #  ##    ####   ##  ##  ##     ## ##    ##  ##          ##
    #    ###    ###    #### ########   ######   ########    ##

    # @!group Widget

    # Check if the server has enabled the widget.
    # @return [true, false] Whether or not the server has enabled the widget.
    def widget_enabled?
      cache_widget
      @widget_enabled
    end

    # Get the channel used to invite members for the widget.
    # @return [Channel, nil] The channel used to generate invites for the widget, or `nil`.
    def widget_channel
      cache_widget
      @bot.channel(@widget_channel_id) if @widget_channel_id
    end

    # Get a URL to an image that can be used to display the server widget on the internet.
    # @param style [String, Symbol, nil] The styling of the widget image. Can be set to one of the
    #   following values: `shield` (default), `banner1`, `banner2`, `banner3`, or `banner4`.
    # @return [String, nil] The URL to the widget's image, or `nil` if the widget has been disabled.
    def widget_url(style: nil)
      API.widget_url(@id, style) if widget_enabled?
    end

    alias_method :widget?, :widget_enabled?
    alias_method :embed_enabled, :widget_enabled?
    alias_method :embed?, :widget_enabled?
    alias_method :embed_channel, :widget_channel

    # @!endgroup

    #  #### ##    ## ##     ## #### ######## ########  ######
    #   ##  ###   ## ##     ##  ##     ##    ##       ##    ##
    #   ##  ####  ## ##     ##  ##     ##    ##       ##
    #   ##  ## ## ## ##     ##  ##     ##    ######    ######
    #   ##  ##  ####  ##   ##   ##     ##    ##             ##
    #   ##  ##   ###   ## ##    ##     ##    ##       ##    ##
    #  #### ##    ##    ###    ####    ##    ########  ######

    # @!group Invites

    # Get the invites for the server.
    # @return [Array<Invite>] The invites for the server.
    def invites
      response = API::Server.invites(@bot.token, @id)
      JSON.parse(response).map { |element| Invite.new(element, @bot) }
    end

    # Get an invite URL to the server using the {#vanity_invite_code vanity invite code}.
    # @return [String, nil] An invite link to the server made using the vanity invite code.
    def vanity_invite_link
      "https://discord.gg/#{@vanity_invite_code}" if @vanity_invite_code
    end

    # Get the vanity invite for the server.
    # @return [VanityInvite, nil] The vanity invite for the server, or `nil` if one isn't set.
    # @note The `MANAGE_SERVER` permission is needed for {VanityInvite#usage_count} to be set.
    def vanity_invite
      if bot.can_manage_server?
        begin
          base = JSON.parse(API::Server.get_vanity_invite(@bot.token, @id))
        rescue Discordrb::Errors::NoPermission
          return nil
        end
      end

      return unless @vanity_invite_code ||= base&.[]('code')

      data = JSON.parse(API::Invite.resolve(@bot.token, @vanity_invite_code))

      (data['uses'] = base['uses'] || 0) if base

      VanityInvite.new(data, self, @bot)
    end

    alias_method :vanity_invite_url, :vanity_invite_link

    # @!endgroup

    #  ########  ########  ##     ## ##    ## ########
    #  ##     ## ##     ## ##     ## ###   ## ##
    #  ##     ## ##     ## ##     ## ####  ## ##
    #  ########  ########  ##     ## ## ## ## ######
    #  ##        ##   ##   ##     ## ##  #### ##
    #  ##        ##    ##  ##     ## ##   ### ##
    #  ##        ##     ##  #######  ##    ## ########

    # @!group Prune

    # Get the prune count for the server.
    # @param days [Integer] The number of days to count for the prune; between 1-30.
    # @param roles [Array<Integer, String, Role>, nil] Include members with these roles.
    # @return [Integer] The amount of members that would be removed in a prune operation.
    # @raise [ArgumentError] If the `days:` parameter is not an {Integer} between 1-30 (inclusive).
    def prune_count!(days:, roles: nil)
      raise ArgumentError, "'days' must be between 1-30" unless days.between?(1, 30)

      include_roles = Array(roles).map(&:resolve_id) if roles

      response = API::Server.get_server_prune_count(@bot.token, @id, days:, include_roles:)
      JSON.parse(response)['pruned']
    end

    # Begin a prune operation to kick inactive members.
    # @param days [Integer] The days worth of inactivity to prune; between 1-30.
    # @param with_count [true, false] Whether the prune count should be returned.
    # @param roles [Array<Integer, String, Role>, nil] Include members with these roles.
    # @param reason [String, nil] The reason to show in the server's audit log for the prune.
    # @return [Integer, nil] The amount of members that were removed in the prune operation, or
    #   `nil` if the `with_count:` parameter was set to `false`.
    # @raise [ArgumentError] If the `days:` parameter is not an {Integer} between 1-30 (inclusive).
    def prune_members(days:, with_count: true, roles: nil, reason: nil)
      raise ArgumentError, "'days' must be between 1-30" unless days.between?(1, 30)

      data = {
        days: days,
        compute_prune_count: with_count || false,
        include_roles: roles ? Array(roles).map(&:resolve_id) : :undef
      }

      response = API::Server.begin_server_prune(@bot.token, @id, **data, reason: reason)
      with_count ? JSON.parse(response)['pruned'] : nil
    end

    # @!endgroup

    #  ########     ###    ##    ##  ######
    #  ##     ##   ## ##   ###   ## ##    ##
    #  ##     ##  ##   ##  ####  ## ##
    #  ########  ##     ## ## ## ##  ######
    #  ##     ## ######### ##  ####       ##
    #  ##     ## ##     ## ##   ### ##    ##
    #  ########  ##     ## ##    ##  ######

    # @!group Bans

    # Unban a user from the server.
    # @param user [User, Member, Integer, String] The user to unban.
    # @param reason [String, nil] The reason to show in the server's audit log for un-banning the user.
    # @return [nil]
    def unban!(user, reason: nil)
      API::Server.unban_user(@bot.token, @id, user.resolve_id, reason)
      nil
    end

    # Ban a user from from server.
    # @param user [User, Member, Integer, String] The user to ban.
    # @param delete_messages [Integer, nil] Delete messages going back by this amount of seconds.
    # @param reason [String, nil] The reason to show in the server's audit log for banning the user.
    # @return [nil]
    def ban!(user, delete_messages: nil, reason: nil)
      API::Server.ban_user!(@bot.token, @id, user.resolve_id, delete_messages, reason)
      nil
    end

    # Ban multiple users from the server in a single operation.
    # @param users [Array<User, Member, Integer, String>] The 1-200 users that should be banned.
    # @param delete_messages [Integer, nil] Delete messages going back by this amount of seconds.
    # @param reason [String, nil] The reason to show in the server's audit log for banning the users.
    # @raise [ArgumentError] If the `users` parameter is not an array between 1-200 elements in size.
    # @return [BulkBan] The resulting data from the ban operation.
    def bulk_ban!(users, delete_messages: nil, reason: nil)
      users = Array(users).map(&:resolve_id)
      raise ArgumentError, 'Can only ban 1-200 users' unless users.size.between?(1, 200)

      response = API::Server.bulk_ban(@bot.token, @id, users, delete_messages, reason)
      BulkBan.new(JSON.parse(response), self, reason)
    rescue Discordrb::Errors::UnableToBulkBanUsers
      BulkBan.new({ 'failed_users' => users }, self, reason)
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
      f_after = after.is_a?(Time) ? IDObject.synthesise(after) : after&.resolve_id
      f_before = before.is_a?(Time) ? IDObject.synthesise(before) : before&.resolve_id

      get_bans = lambda do |before: nil, after: nil|
        data = API::Server.bans(@bot.token, @id, f_limit, before&.id || f_before, after&.id || f_after)
        JSON.parse(data).map { |ban| ServerBan.new(self, @bot.ensure_user(ban['user']), ban['reason']) }
      end

      paginator = Paginator.new(limit, f_before ? :up : :down) do |page|
        if f_before
          get_bans.call(before: page&.first&.user)
        else
          get_bans.call(after: page&.last&.user)
        end
      end

      paginator.to_a
    end

    # @!endgroup

    #   ######   ######  ##     ## ######## ########  ##     ## ##       ######## ########
    #  ##    ## ##    ## ##     ## ##       ##     ## ##     ## ##       ##       ##     ##
    #  ##       ##       ##     ## ##       ##     ## ##     ## ##       ##       ##     ##
    #   ######  ##       ######### ######   ##     ## ##     ## ##       ######   ##     ##
    #        ## ##       ##     ## ##       ##     ## ##     ## ##       ##       ##     ##
    #  ##    ## ##    ## ##     ## ##       ##     ## ##     ## ##       ##       ##     ##
    #   ######   ######  ##     ## ######## ########   #######  ######## ######## ########
    #
    #  ######## ##     ## ######## ##    ## ########  ######
    #  ##       ##     ## ##       ###   ##    ##    ##    ##
    #  ##       ##     ## ##       ###   ##    ##    ##
    #  ######   ##     ## ######   ## ## ##    ##     ######
    #  ##        ##   ##  ##       ##  ####    ##          ##
    #  ##         ## ##   ##       ##   ###    ##    ##    ##
    #  ########    ###    ######## ##    ##    ##     ######

    # @!group Scheduled Events

    # Get the scheduled events for the server.
    # @param bypass_cache [true, false] Whether the cached scheduled events
    #   should be ignored and re-fetched via an HTTP request.
    # @return [Array<ScheduledEvent>] The scheduled events for the server.
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
      cached = @scheduled_events[id]
      return cached if cached || !request

      event = JSON.parse(API::Server.get_scheduled_event(@bot.token, @id, id, with_user_count: true))
      scheduled_event = ScheduledEvent.new(event, self, @bot)
      @scheduled_events[scheduled_event.id] = scheduled_event
    rescue StandardError
      nil
    end

    # Create a new scheduled event.
    # @param name [String] The 1-100 character name of the scheduled event.
    # @param start_time [Time] The start time of the scheduled event.
    # @param entity_type [Integer, Symbol] The entity type of the scheduled event.
    # @param end_time [Time, nil] The end time of the scheduled event.
    # @param channel [Integer, Channel, String, nil] The channel where the scheduled event will take place.
    # @param location [String, nil] The external location of the scheduled event.
    # @param description [String, nil] The 1-1000 character description of the scheduled event.
    # @param cover [File, #read, nil] The cover image of the scheduled event.
    # @param recurrence_rule [#to_h, nil] The recurrence rule of the scheduled event.
    # @param reason [String, nil] The reason to show in the server's audit log for creating the scheduled event.
    # @yieldparam builder [ScheduledEvent::RecurrenceRule::Builder] An optional recurrence rule builder.
    # @return [ScheduledEvent] The scheduled event that was created.
    def create_scheduled_event(
      name:, start_time:, entity_type:, end_time: nil, channel: nil, location: nil,
      description: nil, cover: nil, recurrence_rule: nil, reason: nil
    )
      yield((builder = ScheduledEvent::RecurrenceRule::Builder.new)) if block_given?

      data = {
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

      event = JSON.parse(API::Server.create_scheduled_event(@bot.token, @id, **data, reason: reason))
      scheduled_event = ScheduledEvent.new(event, self, @bot)
      @scheduled_events[scheduled_event.id] = scheduled_event
    end

    # @!endgroup

    #  #### ##    ##  ######  #### ########  ######## ##    ## ########
    #   ##  ###   ## ##    ##  ##  ##     ## ##       ###   ##    ##
    #   ##  ####  ## ##        ##  ##     ## ##       ####  ##    ##
    #   ##  ## ## ## ##        ##  ##     ## ######   ## ## ##    ##
    #   ##  ##  #### ##        ##  ##     ## ##       ##  ####    ##
    #   ##  ##   ### ##    ##  ##  ##     ## ##       ##   ###    ##
    #  #### ##    ##  ######  #### ########  ######## ##    ##    ##
    #
    #     ###     ######  ######## ####  #######  ##    ##  ######
    #    ## ##   ##    ##    ##     ##  ##     ## ###   ## ##    ##
    #   ##   ##  ##          ##     ##  ##     ## ####  ## ##
    #  ##     ## ##          ##     ##  ##     ## ## ## ##  ######
    #  ######### ##          ##     ##  ##     ## ##  ####       ##
    #  ##     ## ##    ##    ##     ##  ##     ## ##   ### ##    ##
    #  ##     ##  ######     ##    ####  #######  ##    ##  ######

    # @!group Security Actions

    # Check if Discord has detected a raid in the server.
    # @return [true, false] Whether or not Discord has detected a raid.
    def raid_detected?
      !@raid_detected_at.nil?
    end

    # Check if Discord has detected DM spam from the server.
    # @return [true, false] Whether or not Discord has detected DM spam.
    def dm_spam_detected?
      !@dm_spam_detected_at.nil?
    end

    # Check if the server has stopped members who aren't friends from DMing each other.
    # @return [true, false] Whether or not the server has disabled non-friend direct messages.
    def dms_disabled?
      !@dms_disabled_until.nil? && @dms_disabled_until > Time.now
    end

    # Check if the server has prevented new members from joining the server, e.g. via invites.
    # @return [true, false] Whether or not invites have been disabled via incident actions or the
    #   `:invites_disabled` server {#features feature}.
    def invites_disabled?
      return true if @features.include?(:invites_disabled)

      !@invites_disabled_until.nil? && @invites_disabled_until > Time.now
    end

    # @!endgroup

    #     ###     ##     ## ########  #### ########       ##        #######   ######
    #    ## ##    ##     ## ##     ##  ##     ##          ##       ##     ## ##    ##
    #   ##   ##   ##     ## ##     ##  ##     ##          ##       ##     ## ##
    #  ##     ##  ##     ## ##     ##  ##     ##          ##       ##     ## ##   ####
    #  #########  ##     ## ##     ##  ##     ##          ##       ##     ## ##    ##
    #  ##     ##  ##     ## ##     ##  ##     ##          ##       ##     ## ##    ##
    #  ##     ##   #######  ########  ####    ##          ########  #######   ######

    # @!group Audit Log

    # Get the audit log for the server.
    # @param limit [Integer, nil] The maximum number of audit log entries to fetch,
    #   or `nil` to fetch all of the matching audit log entries.
    # @param user [User, Member, Integer, String] Filter entries by the user who performed them.
    # @param target [#resolve_id, Integer, String, nil] Filter entries by the entity it affects.
    # @param action [Integer, String, Symbol] Filter entries by the type of action that was done.
    # @param after [Time, #resolve_id, nil] Get audit log entries starting from after this point.
    # @param before [Time, #resolve_id, nil] Get audit log entries starting from before this point.
    # @param oldest_first [true, false, nil] Whether to return audit log entries in oldest to newest order.
    # @note When using the `after` or `oldest_first` parameters, entries will be sorted in ascending order
    #    by entry ID (oldest entries first), and in descending order by entry ID (newest entries first) otherwise.
    # @return [AuditLogs] The audit log for the server.
    def audit_log(
      limit: 50, user: nil, target: nil, action: nil, after: nil, before: nil,
      oldest_first: nil
    )
      if action && !action.is_a?(Integer)
        action = AuditLogs::ACTIONS.key(action.to_sym)
        raise ArgumentError, "Invalid value for the 'action' parameter" unless action
      end

      # rubocop:disable Style/IfUnlessModifier
      if [before, after, oldest_first].count(&:itself) > 1
        raise ArgumentError, "'before', 'after', and 'oldest_first' are mutually exclusive"
      end

      # rubocop:enable Style/IfUnlessModifier
      user = user&.resolve_id
      target = target&.resolve_id
      f_limit = limit && limit <= 100 ? limit : 100
      results = Hash.new { |hash, key| hash[key] = [] }
      f_after = after.is_a?(Time) ? IDObject.synthesise(after) : after&.resolve_id
      f_before = before.is_a?(Time) ? IDObject.synthesise(before) : before&.resolve_id

      # Reverses the list and starts fetching the oldest entries first, in ascending order.
      f_after = 0 if oldest_first

      fetch_audit_log = lambda do |before: nil, after: nil|
        data = JSON.parse(API::Server.get_audit_log(@bot.token, @id,
                                                    limit: f_limit,
                                                    action_type: action,
                                                    user_id: user,
                                                    target_id: target,
                                                    after: after || f_after,
                                                    before: before || f_before))
        data.each do |key, value|
          results[key].concat(value) if key != 'audit_log_entries' && value.is_a?(Array)
        end

        data['audit_log_entries']
      end

      paginator = Paginator.new(limit, :down) do |page|
        if f_after
          fetch_audit_log.call(after: page&.last&.[]('id'))
        else
          fetch_audit_log.call(before: page&.last&.[]('id'))
        end
      end

      AuditLogs.new(self, @bot, results.tap { results['audit_log_entries'] = paginator.to_a })
    end

    alias_method :audit_logs, :audit_log

    # @!endgroup

    #  ########     ######## ########  ########  ########  ######     ###    ######## ######## ########
    #  ##     ##    ##       ##     ## ##     ## ##       ##    ##   ## ##      ##    ##       ##     ##
    #  ##       ##  ##       ##     ## ##     ## ##       ##        ##   ##     ##    ##       ##       ##
    #  ##        ## ######   ########  ########  ######   ##       ##     ##    ##    ######   ##        ##
    #  ##       ##  ##       ##        ##   ##   ##       ##       #########    ##    ##       ##       ##
    #  ##      ##   ##       ##        ##    ##  ##       ##    ## ##     ##    ##    ##       ##      ##
    #  ########     ######## ##        ##     ## ########  ######  ##     ##    ##    ######## ########

    # @!group Deprecated

    # @deprecated This will be removed in 4.0. Please directly access the {#emojis} attribute and call `#any?`.
    def any_emoji?
      @emojis.any?
    end

    # @deprecated This will be removed in 4.0. Please migrate away from using this method.
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

    # @deprecated This will be removed in 4.0. Please migrate to using {#modify} with the `widget_enabled:` parameter.
    def widget_enabled=(value)
      modify_widget(value, widget_channel)
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {#modify} with the `widget_enabled:` parameter.
    def set_widget_enabled(value, reason = nil)
      modify_widget(value, widget_channel, reason)
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {#modify} with the `widget_channel:` parameter.
    def widget_channel=(channel)
      modify_widget(widget?, channel)
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {#modify} with the `widget_channel:` parameter.
    def set_widget_channel(channel, reason = nil)
      modify_widget(widget?, channel, reason)
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {#modify} with the `widget_enabled:` and `widget_channel:` parameters.
    def modify_widget(enabled, channel, reason = nil)
      data = {
        enabled: enabled.nil? ? :undef : enabled,
        channel_id: channel ? channel.resolve_id : :undef
      }

      cache_widget(JSON.parse(API::Server.update_widget(@bot.token, @id, **data, reason:)))
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {#modify}.
    def name=(name)
      modify(name: name)
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {#modify}.
    def icon=(icon)
      modify(icon: icon)
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {#modify}.
    def afk_channel=(afk_channel)
      modify(afk_channel: afk_channel)
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {#modify}.
    def system_channel=(system_channel)
      modify(system_channel: system_channel)
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {#modify}.
    def afk_timeout=(afk_timeout)
      modify(afk_timeout: afk_timeout)
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {#modify}.
    def verification_level=(level)
      modify(verification_level: level)
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {#modify}.
    def default_message_notifications=(notification_level)
      modify(notification_level: notification_level)
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {#modify}.
    def explicit_content_filter=(filter_level)
      modify(explicit_content_filter: filter_level)
    end

    # @deprecated Please directly access the {#channels} attribute and use {#select(&:text?)}.
    def text_channels
      @channels.filter_map { |_, channel| channel if channel.text? }
    end

    # @deprecated This will be removed in 4.0. Please directly access the {#channels} attribute and use `select(&:voice?)`.
    def voice_channels
      @channels.filter_map { |_, channel| channel if channel.voice? }
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {#widget_url} with the `style:` parameter.
    def widget_banner_url(style)
      widget_url(style: style)
    end

    # @deprecated Please migrate to using {create_channel!}.
    def create_channel(name, type = 0, **kwargs)
      create_channel!(name: name, type: type, **kwargs)
    end

    # @deprecated Please migrate to using {#bans!}.
    def bans(limit: nil, before_id: nil, after_id: nil)
      bans!(limit: limit || 1000, before: before_id, after: after_id)
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {#create_emoji}.
    def add_emoji(name, image, roles = [], reason: nil)
      create_emoji(name: name, file: image, roles: roles, reason: reason)
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {Emoji#delete}.
    def delete_emoji(emoji, reason: nil)
      API::Server.delete_emoji(@bot.token, @id, emoji.resolve_id, reason)
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {#query_members}.
    def search_members(name:, limit: nil)
      query_members(name: name, limit: limit || 1).members
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {Emoji#modify}.
    def edit_emoji(emoji, name: nil, roles: nil, reason: nil)
      data = {
        reason: reason,
        name: name || :undef,
        roles: roles ? roles.map(&:resolve_id) : :undef
      }

      data = API::Server.update_emoji(@bot.token, @id, emoji.resolve_id, **data)
      Emoji.new(JSON.parse(data), @bot, self).tap { |emoji| cache_emoji(emoji) }
    end

    # @deprecated This will be removed in 4.0. Please migrate to using {#prune_members}.
    def begin_prune(days, reason = nil)
      prune_members(days: days, with_count: true, reason: reason)
    end

    # @deprecated Please migrate to using {#prune_count!}.
    def prune_count(days, roles: nil)
      prune_count!(days:, roles:)
    end

    # @deprecated This will be removed in 4.0. Voice regions are now determined at the channel level.
    def region
      available_voice_regions.find { |element| element.id == @region_id }
    end

    # @deprecated This will be removed in 4.0. Voice regions are now determined at the channel level.
    def region=(region)
      update_data(JSON.parse(API::Server.update!(@bot.token, @id, region: region.to_s)))
    end

    # @deprecated This will be removed in 4.0.
    def move(user, channel, reason: nil)
      API::Server.update_member(@bot.token, @id, user.resolve_id, channel_id: channel&.resolve_id, reason: reason)
    end

    # @deprecated Please migrate to using {#unban!}.
    def unban(user, reason = nil)
      API::Server.unban_user(@bot.token, @id, user.resolve_id, reason)
    end

    # @deprecated Please migrate to using {#kick!}.
    def kick(user, reason = nil)
      API::Server.remove_member(@bot.token, @id, user.resolve_id, reason)
    end

    # @deprecated Please migrate to using {#ban!}.
    def ban(user, message_days = 0, message_seconds: nil, reason: nil)
      delete_messages = if message_days != 0 && message_days
                          message_days * 86_400
                        else
                          message_seconds || 0
                        end

      API::Server.ban_user!(@bot.token, @id, user.resolve_id, delete_messages, reason)
    end

    # @deprecated Please migrate to using {#bulk_ban!}.
    def bulk_ban(users:, message_seconds: 0, reason: nil)
      raise ArgumentError, 'Can only ban between 1 and 200 users!' unless users.size.between?(1, 200)

      return ban(users.first, 0, message_seconds: message_seconds, reason: reason) if users.size == 1

      response = API::Server.bulk_ban(@bot.token, @id, users.map(&:resolve_id), message_seconds, reason)
      BulkBan.new(JSON.parse(response), self, reason)
    end

    # @deprecated This will be removed in 4.0. The concept of a default channel is seemingly no longer used by Discord.
    def default_channel(send_messages = false)
      me = bot

      items = @channels.filter_map do |_, channel|
        channel if channel.text?
      end

      items.sort_by! do |channel|
        [channel.position, channel.resolve_id]
      end

      items.find do |channel|
        next unless me.can_read_messages?(channel)

        send_messages ? me.can_send_messages?(channel) : true
      end
    end

    alias_method :prune, :begin_prune
    alias_method :emoji?, :any_emoji?
    alias_method :has_emoji?, :any_emoji?
    alias_method :modify_embed, :modify_widget
    alias_method :embed_channel=, :widget_channel=
    alias_method :embed_enabled=, :widget_enabled=
    alias_method :general_channel, :default_channel
    alias_method :set_embed_channel, :set_widget_channel
    alias_method :set_embed_enabled, :set_widget_enabled
    alias_method :content_filter_level=, :explicit_content_filter=
    alias_method :notification_level=, :default_message_notifications=

    # @!endgroup

    #  ####  ###   ## ######## ######## ########  ##    ##    ###    ##        ######
    #   ##   ###   ##    ##    ##       ##     ## ###   ##   ## ##   ##       ##    ##
    #   ##   ####  ##    ##    ##       ##     ## ####  ##  ##   ##  ##       ##
    #   ##   ## ## ##    ##    ######   ########  ## ## ## ##     ## ##        ######
    #   ##   ##  ####    ##    ##       ##   ##   ##  #### ######### ##             ##
    #   ##   ##   ###    ##    ##       ##    ##  ##   ### ##     ## ##       ##    ##
    #  ####  ##    ##    ##    ######## ##     ## ##    ## ##     ## ########  ######

    # @!visibility private
    def cache_role(role)
      @roles[role.id] = role
    end

    # @!visibility private
    def delete_member(user_id)
      @members.delete(user_id)
      @member_count -= 1 unless @member_count <= 0
    end

    # @!visibility private
    def cache_member(member, increment: nil)
      (@member_count += 1) if increment
      @members[member.id] = member
    end

    # @!visibility private
    def cache_scheduled_event(event)
      @scheduled_events[event.id] = event
    end

    # @!visibility private
    def delete_scheduled_event(event)
      @scheduled_events.delete(event.resolve_id)
    end

    # @!visibility private
    def cache_channel(channel)
      @channels[channel.id] = channel
    end

    # @!visibility private
    def delete_channel(id)
      @channels.delete(id)
    end

    # @!visibility private
    def cache_emoji(emoji)
      @emojis[emoji.id] = emoji
    end

    # @!visibility private
    def ensure_member(data, force_cache = true)
      if (member = @members[data['user']['id'].to_i])
        member.update_data(data) if force_cache
      else
        member = Member.new(data, self, @bot)
        cache_member(member)
      end

      member
    end

    # @!visibility private
    def delete_role(role_id)
      @roles.delete(role_id.resolve_id)

      @members.each_value do |member|
        new_roles = member.roles.reject { |role| role.id == role_id }
        member.update_roles(new_roles)
      end

      @channels.each_value do |channel|
        overwrites = channel.permission_overwrites.reject { |id, _| id == role_id }
        channel.update_overwrites(overwrites)
      end
    end

    # @!visibility private
    def update_role_positions(roles, reason: nil)
      data = API::Server.update_role_positions(@bot.token, @id, roles, reason)
      JSON.parse(data).each { |hash| @roles[hash['id'].to_i]&.update_data(hash) }
    end

    # @!visibility private
    def clear_threads(ids = nil)
      if ids.nil?
        @channels.delete_if { |_, channel| channel.thread? }
      else
        @channels.delete_if { |_, channel| channel.thread? && ids.any?(channel.parent&.id) }
      end
    end

    # @!visibility private
    def process_chunk(members, chunk_index, chunk_count, nonce, not_found, presences)
      return (@member_chunk_queries[nonce] = { members:, not_found: }) if nonce && @member_chunk_queries.key?(nonce)

      process_members(members)
      process_presences(presences) if presences
      LOGGER.debug("Processed chunk #{chunk_index + 1}/#{chunk_count} server #{@id} - index #{chunk_index} - length #{members.length}")

      return if chunk_index + 1 < chunk_count

      LOGGER.debug("Finished chunking server #{@id}")

      # Reset everything to normal
      @chunked = true
    end

    # @!visibility private
    def update_voice_state(data)
      user_id = data['user_id'].to_i

      if data['channel_id']
        unless @voice_states[user_id]
          # Create a new voice state for the user
          @voice_states[user_id] = VoiceState.new(user_id)
        end

        # Update the existing voice state (or the one we just created)
        channel = @channels[data['channel_id'].to_i]
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

    # @!visibility private
    def inspect
      "<Server id=#{@id} name=\"#{@name}\" large=#{@large} member_count=#{@member_count}>"
    end

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
      @notification_level = new_data['default_message_notifications']

      @features = new_data['features']&.map { |feature| feature.downcase.to_sym } || @features || []
      @max_presence_count = new_data['max_presences'] if new_data.key?('max_presences')
      @max_member_count = new_data['max_members'] if new_data.key?('max_members')
      @large = new_data.key?('large') ? new_data['large'] : (@large || false)
      @member_count = new_data['member_count'] || new_data['approximate_member_count'] || @member_count || 0

      @vanity_invite_code = new_data['vanity_url_code']
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
      process_emojis(new_data['emojis']) if new_data['emojis']
      process_members(new_data['members']) if new_data['members']
      process_presences(new_data['presences']) if new_data['presences']
      process_voice_states(new_data['voice_states']) if new_data['voice_states']
      process_active_threads(new_data['threads']) if new_data['threads']
      process_incident_actions(new_data['incidents_data']) if new_data.key?('incidents_data')
      process_scheduled_events(new_data['guild_scheduled_events']) if new_data['guild_scheduled_events']
    end

    private

    # @!visibility private
    def cache_widget(data = nil)
      return if !@widget_enabled.nil? && !data

      data ||= if bot.can_manage_server?
                 JSON.parse(API::Server.widget(@bot.token, @id))
               else
                 return update_data(nil)
               end

      @widget_enabled = data['enabled']
      @widget_channel_id = data['channel_id']
    end

    def process_roles(roles)
      @roles = {}

      return unless roles

      roles.each do |element|
        role = Role.new(element, @bot, self)
        @roles[role.id] = role
      end
    end

    def process_emojis(emojis)
      @emojis = {}

      return unless emojis

      emojis.each do |element|
        emoji = Emoji.new(element, @bot, self)
        @emojis[emoji.id] = emoji
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
        next unless (user = element['user'])

        @members[user['id'].to_i]&.update_presence(element)
      end
    end

    def process_channels(channels)
      @channels = {}

      return unless channels

      channels.each do |element|
        channel = @bot.ensure_channel(element, self)
        @channels[channel.id] = channel
      end
    end

    def process_voice_states(voice_states)
      return unless voice_states

      voice_states.each do |element|
        update_voice_state(element)
      end
    end

    def process_active_threads(threads)
      @channels ||= {}

      return unless threads

      threads.each do |element|
        thread = @bot.ensure_channel(element, self)
        @channels[thread.id] = thread
      end
    end

    def process_incident_actions(incidents)
      incidents&.each do |key, value|
        case key
        when 'raid_detected_at'
          @raid_detected_at = value ? Time.parse(value) : value
        when 'dms_disabled_until'
          @dms_disabled_until = value ? Time.parse(value) : value
        when 'dm_spam_detected_at'
          @dm_spam_detected_at = value ? Time.parse(value) : value
        when 'invites_disabled_until'
          @invites_disabled_until = value ? Time.parse(value) : value
        end
      end
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
    # @return [String, nil] the reason the user was banned, if provided.
    attr_reader :reason

    # @return [User] the user that was banned.
    attr_reader :user

    # @return [Server] the server the ban belongs to.
    attr_reader :server

    # @!visibility private
    def initialize(server, user, reason)
      @server = server
      @user = user
      @reason = reason
    end

    # Removes this ban on the associated user in the server.
    # @param reason [String] the reason for removing the ban.
    def remove(reason = nil)
      @server.unban!(user, reason:)
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

  # A set of messages collected from a search query.
  class SearchedMessages
    include Enumerable

    # @return [Array<Message>] the messages that matched the search query.
    attr_reader :messages

    # @return [Integer] the total number of messages that matched the search query.
    attr_reader :total_results

    # @!visibility private
    def initialize(messages, total, bot)
      @bot = bot
      @messages = messages
      @total_results = total
    end

    # Get a single message that matched the search query by its index.
    # @param index [Integer] The index of the message to get from the array.
    # @return [Message] the message that was found at the specified index.
    def [](index)
      @messages[index]
    end

    # Iterate over each message that matched the search query.
    # @return [Array<Message>, Enumerable] The array that was iterated over.
    def each(...)
      @messages.each(...)
    end

    # @!visibility private
    def inspect
      "<SearchedMessages messages=[#{'...' if @messages.any?}] total_results=#{@total_results}>"
    end
  end

  # A set of matching members.
  class QueriedMembers
    include Enumerable

    # @return [Server] the server the members were queried for.
    attr_reader :server

    # @return [Array<Member>] the members that matched the query.
    attr_reader :members

    # @return [Array<Integer>] the invalid user IDs that were passed.
    attr_reader :not_found

    # @return [true, false] whether or not the gateway query timed-out.
    attr_reader :timed_out
    alias timed_out? timed_out

    # @!visibility private
    def initialize(data, server, bot)
      @bot = bot
      @server = server
      @timed_out = data[:timeout] || false
      @not_found = data[:not_found]&.map(&:to_i) || []
      @members = data[:members]&.map { |item| @server.ensure_member(item) } || []
    end

    # @!visibility private
    def each(...)
      @members.each(...)
    end

    # @!visibility private
    def inspect
      "<QueriedMembers members=[#{'...' if @members.any?}] timed_out=#{@timed_out}>"
    end
  end
end
