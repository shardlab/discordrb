# frozen_string_literal: true

module Discordrb
  # A Discord role that contains permissions and applies to certain users
  class Role
    include IDObject

    # @return [Permissions] this role's permissions.
    attr_reader :permissions

    # @return [String] this role's name ("new role" if it hasn't been changed)
    attr_reader :name

    # @return [Server] the server this role belongs to
    attr_reader :server

    # @return [true, false] whether or not this role should be displayed separately from other users
    attr_reader :hoist
    alias_method :hoist?, :hoist

    # @return [true, false] whether or not this role is managed by an integration or a bot
    attr_reader :managed
    alias_method :managed?, :managed

    # @return [true, false] whether this role can be mentioned using a role mention
    attr_reader :mentionable
    alias_method :mentionable?, :mentionable

    # @return [ColourRGB] the primary colour of this role.
    attr_reader :colour
    alias_method :color, :colour

    # @return [Integer] the position of this role in the hierarchy
    attr_reader :position

    # @return [String, nil] The icon hash for this role.
    attr_reader :icon

    # @return [Tags, nil] The role tags.
    attr_reader :tags

    # @return [Integer] The flags for this role.
    attr_reader :flags

    # @return [String, nil] The unicode emoji of this role, or nil.
    attr_reader :unicode_emoji

    # @return [ColourRGB, nil] the secondary colour of this role.
    attr_reader :secondary_colour
    alias_method :secondary_color, :secondary_colour

    # @return [ColourRGB, nil] the tertiary colour of this role.
    attr_reader :tertiary_colour
    alias_method :tertiary_color, :tertiary_colour

    # Wrapper for the role tags
    class Tags
      # @return [Integer, nil] The ID of the bot this role belongs to
      attr_reader :bot_id

      # @return [Integer, nil] The ID of the integration this role belongs to
      attr_reader :integration_id

      # @return [true, false] Whether this is the guild's Booster role
      attr_reader :premium_subscriber
      alias_method :premium_subscriber?, :premium_subscriber

      # @return [Integer, nil] The id of this role's subscription sku and listing
      attr_reader :subscription_listing_id

      # @return [true, false] Whether this role is available for purchase
      attr_reader :available_for_purchase
      alias_method :available_for_purchase?, :available_for_purchase

      # @return [true, false] Whether this role is a guild's linked role
      attr_reader :guild_connections
      alias_method :guild_connections?, :guild_connections
      alias_method :server_connections?, :guild_connections

      # @!visibility private
      def initialize(data)
        @bot_id = data['bot_id']&.resolve_id
        @integration_id = data['integration_id']&.resolve_id
        @premium_subscriber = data.key?('premium_subscriber')
        @subscription_listing_id = data['subscription_listing_id']&.resolve_id
        @available_for_purchase = data.key?('available_for_purchase')
        @guild_connections = data.key?('guild_connections')
      end
    end

    # This class is used internally as a wrapper to a Role object that allows easy writing of permission data.
    class RoleWriter
      # @!visibility private
      def initialize(role, token)
        @role = role
        @token = token
      end

      # Write the specified permission data to the role, without updating the permission cache
      # @param bits [Integer] The packed permissions to write.
      def write(bits)
        @role.send(:packed=, bits, false)
      end

      # The inspect method is overridden, in this case to prevent the token being leaked
      def inspect
        "<RoleWriter role=#{@role} token=...>"
      end
    end

    # @!visibility private
    def initialize(data, bot, server = nil)
      @bot = bot
      @server = server
      @permissions = Permissions.new(data['permissions'].to_i, RoleWriter.new(self, @bot.token))
      @name = data['name']
      @id = data['id'].to_i

      @position = data['position']

      @hoist = data['hoist']
      @mentionable = data['mentionable']
      @managed = data['managed']

      colours = data['colors']
      @colour = ColourRGB.new(colours['primary_color'])

      @icon = data['icon']

      @tags = Tags.new(data['tags']) if data['tags']

      @flags = data['flags']

      @unicode_emoji = data['unicode_emoji']

      @tertiary_colour = ColourRGB.new(colours['tertiary_color']) if colours['tertiary_color']
      @secondary_colour = ColourRGB.new(colours['secondary_color']) if colours['secondary_color']
    end

    # @return [String] a string that will mention this role, if it is mentionable.
    def mention
      "<@&#{@id}>"
    end

    # @return [Array<Member>] an array of members who have this role.
    # @note This requests a member chunk if it hasn't for the server before, which may be slow initially
    def members
      @server.members.select { |m| m.role? self }
    end

    alias_method :users, :members

    # Updates the data cache from another Role object
    # @note For internal use only
    # @!visibility private
    def update_from(other)
      @permissions = other.permissions
      @name = other.name
      @hoist = other.hoist
      @colour = other.colour
      @position = other.position
      @managed = other.managed
      @icon = other.icon
      @flags = other.flags
      @unicode_emoji = other.unicode_emoji
      @secondary_colour = other.secondary_colour
      @tertiary_colour = other.tertiary_colour
    end

    # Updates the data cache from a hash containing data
    # @note For internal use only
    # @!visibility private
    def update_data(new_data)
      @name = new_data['name']
      @hoist = new_data['hoist']
      @icon = new_data['icon']
      @unicode_emoji = new_data['unicode_emoji']
      @position = new_data['position']
      @mentionable = new_data['mentionable']
      @flags = new_data['flags']
      colours = new_data['colors']
      @permissions.bits = new_data['permissions'].to_i
      @colour = ColourRGB.new(colours['primary_color'])
      @secondary_color = ColourRGB.new(colours['secondary_color']) if colours['secondary_color']
      @tertiary_colour = ColourRGB.new(colours['tertiary_color']) if colours['tertiary_color']
    end

    # Sets the role name to something new
    # @param name [String] The name that should be set
    def name=(name)
      update_role_data(name: name)
    end

    # Changes whether or not this role is displayed at the top of the user list
    # @param hoist [true, false] The value it should be changed to
    def hoist=(hoist)
      update_role_data(hoist: hoist)
    end

    # Changes whether or not this role can be mentioned
    # @param mentionable [true, false] The value it should be changed to
    def mentionable=(mentionable)
      update_role_data(mentionable: mentionable)
    end

    # Sets the primary role colour to something new.
    # @param colour [ColourRGB, Integer, nil] The new colour.
    def colour=(colour)
      update_colors(primary: colour)
    end

    # Sets the secondary role colour to something new.
    # @param colour [ColourRGB, Integer, nil] The new secondary colour.
    def secondary_colour=(colour)
      update_colours(secondary: colour)
    end

    # Sets the tertiary role colour to something new.
    # @param colour [ColourRGB, Integer, nil] The new tertiary colour.
    def tertiary_colour=(colour)
      update_colours(tertiary: colour)
    end

    # Sets whether the role colour should be a holographic style.
    # @param holographic [true, false] whether the role colour should be a holographic style.
    def holographic=(holographic)
      update_colours(holographic: holographic)
    end

    # Upload a role icon for servers with the ROLE_ICONS feature.
    # @param file [File, nil] File like object that responds to #read, or nil.
    def icon=(file)
      update_role_data(icon: file)
    end

    # Set a role icon to a unicode emoji for servers with the ROLE_ICONS feature.
    # @param emoji [String, nil] The new unicode emoji for this role, or nil.
    def unicode_emoji=(emoji)
      update_role_data(unicode_emoji: emoji)
    end

    # @param format ['webp', 'png', 'jpeg']
    # @return [String] URL to the icon on Discord's CDN.
    def icon_url(format = 'webp')
      return nil unless @icon

      Discordrb::API.role_icon_url(@id, @icon, format)
    end

    # Get the icon that a role has displayed.
    # @return [String, nil] Icon URL, the unicode emoji, or nil if this role doesn't have any icon.
    # @note A role can have a unicode emoji, and an icon, but only the icon will be shown in the UI.
    def display_icon
      icon_url || unicode_emoji
    end

    # Set the icon this role is displaying.
    # @param icon [File, String, nil] File like object that responds to #read, unicode emoji, or nil.
    # @note Setting the icon to nil will remove the unicode emoji **and** the custom icon.
    def display_icon=(icon)
      if icon.nil?
        update_role_data(unicode_emoji: nil, icon: nil)
        return
      end

      if icon.respond_to?(:read)
        update_role_data(unicode_emoji: nil, icon: icon)
      else
        update_role_data(unicode_emoji: icon, icon: nil)
      end
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

    alias_method :color=, :colour=
    alias_method :secondary_color=, :secondary_colour=
    alias_method :tertiary_color=, :tertiary_colour=

    # Changes this role's permissions to a fixed bitfield. This allows setting multiple permissions at once with just
    # one API call.
    #
    # Information on how this bitfield is structured can be found at
    # https://discord.com/developers/docs/topics/permissions.
    # @example Remove all permissions from a role
    #   role.packed = 0
    # @param packed [Integer] A bitfield with the desired permissions value.
    # @param update_perms [true, false] Whether the internal data should also be updated. This should always be true
    #   when calling externally.
    def packed=(packed, update_perms = true)
      update_role_data(permissions: packed)
      @permissions.bits = packed if update_perms
    end

    # Moves this role above another role in the list.
    # @param other [Role, String, Integer, nil] The role, or its ID, above which this role should be moved. If it is `nil`,
    #   the role will be moved above the @everyone role.
    # @return [Integer] the new position of this role
    def sort_above(other = nil)
      other = @server.role(other.resolve_id) if other
      roles = @server.roles.sort_by(&:position)
      roles.delete_at(@position)

      index = other ? roles.index { |role| role.id == other.id } + 1 : 1
      roles.insert(index, self)

      updated_roles = roles.map.with_index { |role, position| { id: role.id, position: position } }
      @server.update_role_positions(updated_roles)
      index
    end

    alias_method :move_above, :sort_above

    # Deletes this role. This cannot be undone without recreating the role!
    # @param reason [String] the reason for this role's deletion
    def delete(reason = nil)
      API::Server.delete_role(@bot.token, @server.id, @id, reason)
      @server.delete_role(@id)
    end

    # A rich interface designed to make working with role colours simple.
    # @param primary [ColourRGB, Integer, nil] The new primary/base colour of this role, or nil to clear the primary colour.
    # @param secondary [ColourRGB, Integer, nil] The new secondary colour of this role, or nil to clear the secondary colour.
    # @param tertiary [ColourRGB, Integer,nil] The new tertiary colour of this role, or nil to clear the tertiary colour.
    # @param holographic [true, false] Whether to apply or remove the holographic style to the role colour, overriding any other
    #   arguments that were passed. Using this argument is recommended over passing individual colours.
    def update_colours(primary: :undef, secondary: :undef, tertiary: :undef, holographic: :undef)
      colours = {
        primary_color: (primary == :undef ? @colour : primary)&.to_i,
        tertiary_color: (tertiary == :undef ? @tertiary_colour : tertiary)&.to_i,
        secondary_color: (secondary == :undef ? @secondary_colour : secondary)&.to_i
      }

      holographic_colours = {
        primary_color: 11_127_295,
        tertiary_color: 16_761_760,
        secondary_color: 16_759_788
      }

      # Only set the tertiary_color to `nil` if holographic is explicitly set to false.
      colours[:tertiary_color] = nil if holographic.is_a?(FalseClass) && holographic?

      update_role_data(colours: holographic == true ? holographic_colours : colours)
    end

    alias_method :update_colors, :update_colours

    # The inspect method is overwritten to give more useful output
    def inspect
      "<Role name=#{@name} permissions=#{@permissions.inspect} hoist=#{@hoist} colour=#{@colour.inspect} server=#{@server.inspect} position=#{@position} mentionable=#{@mentionable} unicode_emoji=#{@unicode_emoji} flags=#{@flags}>"
    end

    private

    def update_role_data(new_data)
      update_data(JSON.parse(API::Server.update_role(@bot.token, @server.id, @id,
                                                     new_data[:name] || @name,
                                                     :undef,
                                                     new_data.key?(:hoist) ? new_data[:hoist] : :undef,
                                                     new_data.key?(:mentionable) ? new_data[:mentionable] : :undef,
                                                     new_data[:permissions] || @permissions.bits,
                                                     nil,
                                                     new_data.key?(:icon) ? new_data[:icon] : :undef,
                                                     new_data.key?(:unicode_emoji) ? new_data[:unicode_emoji] : :undef,
                                                     new_data.key?(:colours) ? new_data[:colours] : :undef)))
    end
  end
end
