# frozen_string_literal: true

require 'discordrb/data'

module Discordrb
  # This mixin module does caching stuff for the library. It conveniently separates the logic behind
  # the caching (like, storing the user hashes or making API calls to retrieve things) from the Bot that
  # actually uses it.
  module Cache
    # Initializes this cache
    def init_cache
      @users = {}

      @voice_regions = {}

      @guilds = {}

      @channels = {}
      @pm_channels = {}
    end

    # Returns or caches the available voice regions
    def voice_regions
      return @voice_regions unless @voice_regions.empty?

      regions = JSON.parse API.voice_regions(token)
      regions.each do |data|
        @voice_regions[data[:id]] = VoiceRegion.new(data)
      end

      @voice_regions
    end

    # Gets a channel given its ID. This queries the internal channel cache, and if the channel doesn't
    # exist in there, it will get the data from Discord.
    # @param id [Integer] The channel ID for which to search for.
    # @param guild [Guild] The guild for which to search the channel for. If this isn't specified, it will be
    #   inferred using the API
    # @return [Channel, nil] The channel identified by the ID.
    # @raise Discordrb::Errors::NoPermission
    def channel(id, guild = nil)
      id = id.resolve_id

      debug("Obtaining data for channel with id #{id}")
      return @channels[id] if @channels[id]

      begin
        response = @client.get_channel(id)
      rescue Discordrb::Errors::UnknownChannel
        return nil
      end
      channel = Channel.new(response, self, guild)
      @channels[id] = channel
    end

    alias_method :group_channel, :channel

    # Gets a user by its ID.
    # @note This can only resolve users known by the bot (i.e. that share a guild with the bot).
    # @param id [Integer] The user ID that should be resolved.
    # @return [User, nil] The user identified by the ID, or `nil` if it couldn't be found.
    def user(id)
      id = id.resolve_id
      return @users[id] if @users[id]

      LOGGER.out("Resolving user #{id}")
      begin
        response = @client.get_user(id)
      rescue Discordrb::Errors::UnknownUser
        return nil
      end
      user = User.new(response, self)
      @users[id] = user
    end

    # Gets a guild by its ID.
    # @note This can only resolve guilds the bot is currently in.
    # @param id [Integer] The guild ID that should be resolved.
    # @return [Guild, nil] The guild identified by the ID, or `nil` if it couldn't be found.
    def guild(id)
      id = id.resolve_id
      return @guilds[id] if @guilds[id]

      LOGGER.out("Resolving guild #{id}")
      begin
        response = @client.get_guild(id)
      rescue Discordrb::Errors::NoPermission
        return nil
      end
      guild = Guild.new(response, self)
      @guilds[id] = guild
    end

    # Gets a member by both IDs, or `Guild` and user ID.
    # @param guild_or_id [Guild, Integer] The `Guild` or guild ID for which a member should be resolved
    # @param user_id [Integer] The ID of the user that should be resolved
    # @return [Member, nil] The member identified by the IDs, or `nil` if none could be found
    def member(guild_or_id, user_id)
      guild_id = guild_or_id.resolve_id
      user_id = user_id.resolve_id
      guild = guild_or_id.is_a?(Guild) ? guild_or_id : self.guild(guild_id)

      return guild.member(user_id) if guild.member_cached?(user_id)

      LOGGER.out("Resolving member #{guild_id} on guild #{user_id}")
      begin
        response = @client.get_guild_member(guild_id, user_id)
      rescue Discordrb::Errors::UnknownUser, Discordrb::Errors::UnknownMember
        return nil
      end
      member = Member.new(response, guild, self)
      guild.cache_member(member)
    end

    # Creates a PM channel for the given user ID, or if one exists already, returns that one.
    # It is recommended that you use {User#pm} instead, as this is mainly for internal use. However,
    # usage of this method may be unavoidable if only the user ID is known.
    # @param id [Integer] The user ID to generate a private channel for.
    # @return [Channel] A private channel for that user.
    def pm_channel(id)
      id = id.resolve_id
      return @pm_channels[id] if @pm_channels[id]

      debug("Creating pm channel with user id #{id}")
      response = @client.create_dm(id)
      channel = Channel.new(response, self)
      @pm_channels[id] = channel
    end

    alias_method :private_channel, :pm_channel

    # Ensures a given user object is cached and if not, cache it from the given data hash.
    # @param data [Hash] A data hash representing a user.
    # @return [User] the user represented by the data hash.
    def ensure_user(data)
      if @users.include?(data[:id].to_i)
        @users[data[:id].to_i]
      else
        @users[data[:id].to_i] = User.new(data, self)
      end
    end

    # Ensures a given guild object is cached and if not, cache it from the given data hash.
    # @param data [Hash] A data hash representing a guild.
    # @param force_cache [true, false] Whether the object in cache should be updated with the given
    #   data if it already exists.
    # @return [Guild] the guild represented by the data hash.
    def ensure_guild(data, force_cache = false)
      if @guilds.include?(data[:id].to_i)
        guild = @guilds[data[:id].to_i]
        guild.update_data(data) if force_cache
        guild
      else
        @guilds[data[:id].to_i] = Guild.new(data, self)
      end
    end

    # Ensures a given channel object is cached and if not, cache it from the given data hash.
    # @param data [Hash] A data hash representing a channel.
    # @param guild [Guild, nil] The guild the channel is on, if known.
    # @return [Channel] the channel represented by the data hash.
    def ensure_channel(data, guild = nil)
      if @channels.include?(data[:id].to_i)
        @channels[data[:id].to_i]
      else
        @channels[data[:id].to_i] = Channel.new(data, self, guild)
      end
    end

    # Requests member chunks for a given guild ID.
    # @param id [Integer] The guild ID to request chunks for.
    def request_chunks(id)
      @gateway.send_request_members(id, '', 0)
    end

    # Gets the code for an invite.
    # @param invite [String, Invite] The invite to get the code for. Possible formats are:
    #
    #    * An {Invite} object
    #    * The code for an invite
    #    * A fully qualified invite URL (e.g. `https://discord.com/invite/0A37aN7fasF7n83q`)
    #    * A short invite URL with protocol (e.g. `https://discord.gg/0A37aN7fasF7n83q`)
    #    * A short invite URL without protocol (e.g. `discord.gg/0A37aN7fasF7n83q`)
    # @return [String] Only the code for the invite.
    def resolve_invite_code(invite)
      invite = invite.code if invite.is_a? Discordrb::Invite
      invite = invite[invite.rindex('/') + 1..] if invite.start_with?('http', 'discord.gg')
      invite
    end

    # Gets information about an invite.
    # @param invite [String, Invite] The invite to join. For possible formats see {#resolve_invite_code}.
    # @return [Invite] The invite with information about the given invite URL.
    def invite(invite)
      code = resolve_invite_code(invite)
      Invite.new(@client.get_invite(code), self)
    end

    # Finds a channel given its name and optionally the name of the guild it is in.
    # @param channel_name [String] The channel to search for.
    # @param guild_name [String] The guild to search for, or `nil` if only the channel should be searched for.
    # @param type [Integer, nil] The type of channel to search for (0: text, 1: private, 2: voice, 3: group), or `nil` if any type of
    #   channel should be searched for
    # @return [Array<Channel>] The array of channels that were found. May be empty if none were found.
    def find_channel(channel_name, guild_name = nil, type: nil)
      results = []

      if /<#(?<id>\d+)>?/ =~ channel_name
        # Check for channel mentions separately
        return [channel(id)]
      end

      @guilds.each_value do |guild|
        guild.channels.each do |channel|
          results << channel if channel.name == channel_name && (guild_name || guild.name) == guild.name && (!type || (channel.type == type))
        end
      end

      results
    end

    # Finds a user given its username or username & discriminator.
    # @overload find_user(username)
    #   Find all cached users with a certain username.
    #   @param username [String] The username to look for.
    #   @return [Array<User>] The array of users that were found. May be empty if none were found.
    # @overload find_user(username, discrim)
    #   Find a cached user with a certain username and discriminator.
    #   Find a user by name and discriminator
    #   @param username [String] The username to look for.
    #   @param discrim [String] The user's discriminator
    #   @return [User, nil] The user that was found, or `nil` if none was found
    # @note This method only searches through users that have been cached. Users that have not yet been cached
    #   by the bot but still share a connection with the user (mutual guild) will not be found.
    # @example Find users by name
    #   bot.find_user('z64') #=> Array<User>
    # @example Find a user by name and discriminator
    #   bot.find_user('z64', '2639') #=> User
    def find_user(username, discrim = nil)
      users = @users.values.find_all { |e| e.username == username }
      return users.find { |u| u.discrim == discrim } if discrim

      users
    end
  end
end
