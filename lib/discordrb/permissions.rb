# frozen_string_literal: true

module Discordrb
  # Represents a set of Discord permissions.
  class Permissions
    # Mapping of bit positions to permission names.
    FLAGS = {
      # Bit => Permission # Value
      0 => :create_instant_invite,        # 1
      1 => :kick_members,                 # 2
      2 => :ban_members,                  # 4
      3 => :administrator,                # 8
      4 => :manage_channels,              # 16
      5 => :manage_server,                # 32
      6 => :add_reactions,                # 64
      7 => :view_audit_log,               # 128
      8 => :priority_speaker,             # 256
      9 => :stream,                       # 512
      10 => :read_messages,               # 1024
      11 => :send_messages,               # 2048
      12 => :send_tts_messages,           # 4096
      13 => :manage_messages,             # 8192
      14 => :embed_links,                 # 16384
      15 => :attach_files,                # 32768
      16 => :read_message_history,        # 65536
      17 => :mention_everyone,            # 131072
      18 => :use_external_emoji,          # 262144
      19 => :view_server_insights,        # 524288
      20 => :connect,                     # 1048576
      21 => :speak,                       # 2097152
      22 => :mute_members,                # 4194304
      23 => :deafen_members,              # 8388608
      24 => :move_members,                # 16777216
      25 => :use_voice_activity,          # 33554432
      26 => :change_nickname,             # 67108864
      27 => :manage_nicknames,            # 134217728
      28 => :manage_roles,                # 268435456, also Manage Permissions
      29 => :manage_webhooks,             # 536870912
      30 => :manage_emojis,               # 1073741824, also Manage Stickers
      31 => :use_slash_commands,          # 2147483648
      32 => :request_to_speak,            # 4294967296
      33 => :manage_events,               # 8589934592
      34 => :manage_threads,              # 17179869184
      35 => :use_public_threads,          # 34359738368
      36 => :use_private_threads,         # 68719476736
      37 => :use_external_stickers,       # 137438953472
      38 => :send_messages_in_threads,    # 274877906944
      39 => :use_embedded_activities,     # 549755813888
      40 => :moderate_members,            # 1099511627776
      41 => :view_monetization_analytics, # 2199023255552
      42 => :use_soundboard,              # 4398046511104
      43 => :create_server_expressions,   # 8796093022208
      44 => :create_scheduled_events,     # 17592186044416
      45 => :use_external_sounds,         # 35184372088832
      46 => :send_voice_messages,         # 70368744177664
      49 => :send_polls,                  # 562949953421312
      50 => :use_external_apps,           # 1125899906842624
      51 => :pin_messages,                # 2251799813685248
      52 => :bypass_slowmode              # 4503599627370496
    }.freeze

    # @!visibility private
    IMPLICIT = {
      timeout: 8_584_986_789_608_447,
      send_messages: 6_262_955_671_212_032,
      stage: 2_952_866_897 | 12_906_922_496,
      voice: 2_952_866_897 | 286_431_435_031_296,
      text: 2_952_866_897 | 2_252_744_706_490_368
    }.freeze

    # @!visibility private
    MASKS = FLAGS.to_h { |bit, name| [name, 1 << bit] }.freeze

    # @return [Integer] the raw bitfield representing the permissions.
    attr_reader :bits

    # Create a new permissions object.
    # @example Create a new permissions object for a list of specific permissions.
    #   Permissions.new([:read_messages, :connect, :speak])
    # @example Create a blank permissions object and then add specific permissions.
    #   permission = Permissions.new
    #   permission.can_bypass_slowmode = true
    #   permission.can_use_slash_commands = true
    #   permission.can_send_messages_in_threads = true
    # @param bits [String, Integer, Array<Symbol, String>] The raw bitfield that should
    #   be initially set, or a collection of permission symbols.
    # @param writer [RoleWriter, nil] The role writer that should be used. This parameter
    #   is **deprecated**, and its usage is no longer encouraged.
    def initialize(bits = 0, writer = nil)
      self.bits = bits
      (@role_writer = writer) if writer
    end

    MASKS.each do |name, mask|
      define_method("can_#{name}=") do |state|
        result = if state
                   @bits | mask
                 else
                   @bits & ~mask
                 end

        # TODO: remove this at some point in 4.0.
        @role_writer&.write(result)

        # API call first, update local state after.
        @bits = result
      end

      define_method(name) { @bits.anybits?(mask) }
    end

    alias_method :administrate, :administrator
    alias_method :can_administrate=, :can_administrator=

    # Compare two permission objects based off of their bitfield.
    # @param other [Permissions, Object] The permissions object to compare this one against.
    # @return [true, false] Whether or not the two permission objects represent the same bitfield.
    def ==(other)
      other.is_a?(Permissions) ? (@bits == other.bits) : false
    end

    alias_method :eql?, :==

    # Return the corresponding bitfield for an array of permission symbols.
    # @example Get the bits for permissions that could send voice messages and manage channels.
    #   Permissions.bits([:send_voice_messages, :manage_channels]) # => 3146752
    # @param collection [Array<Symbol, String>] The permission symbols to compute the bitfield for.
    # @return [Integer] The corresponding bitfield value for the provided permissions.
    def self.bits(collection)
      collection.reduce(0) { |sum, element| sum | MASKS[element.to_sym] }
    end

    # Set the bits that the permission object should represent.
    # @param bits [String, Integer, Array<Symbol, String>] The raw bitfield that
    #   should be initially set, or a collection of permission symbols.
    # @return [Integer] The new bitfield value that was set for the permissions object.
    def bits=(bits)
      @bits = bits.respond_to?(:map) ? Permissions.bits(bits) : bits.to_i
    end

    # Get the permissions for the permission object as an array of symbols.
    # @example Get the permissions for the bitfield value "274877908992"
    #   permissions = Permissions.new(274877908992)
    #   permissions.defined_permissions # => [:send_messages, :send_messages_in_threads]
    # @return [Array<Symbol>] The symbols for the permissions that represent the permissions object.
    def defined_permissions
      MASKS.filter_map { |name, value| @bits.anybits?(value) ? name : nil }
    end
  end

  # Mixin to calculate permissions for server members.
  module PermissionCalculator
    # Checks whether this user can do the particular action, regardless of whether it has the permission defined, through for example being
    #   the server owner or having the Manage Roles permission.
    # @param permission [Symbol] The permission that should be checked. See also {Permissions::FLAGS} for a list.
    # @param channel [Channel, nil] If channel overrides should be checked too, this channel specifies where the overrides should be checked.
    # @example Check if the bot can send messages to a specific channel in a server.
    #   bot_profile = bot.profile.on(event.server)
    #   can_send_messages = bot_profile.permission?(:send_messages, channel)
    # @return [true, false] Whether or not this user has the permission.
    def permission?(permission, channel = nil)
      # Interaction events already give us the permissions (including implicit
      # permissions as well), so we can just delegate to that and call it a day.
      return @permissions.__send__(permission) if @permissions && !channel

      return true if owner?

      base = server.everyone_role.permissions.bits

      roles.each do |role|
        base |= role.permissions.bits

        return true if role.permissions.administrator
      end

      # rubocop:disable Style/IfUnlessModifier
      if channel && !channel.is_a?(Channel)
        channel = @bot.channel(channel.resolve_id)
      end

      # rubocop:enable Style/IfUnlessModifier
      computed = if channel
                   compute_overwrites(base, channel, true)
                 else
                   base
                 end

      # Members in timeout straight-up lose everything except
      # `:read_messages` and the `:read_message_history` permission.
      (computed &= ~Permissions::IMPLICIT[:timeout]) if timeout?

      if channel&.thread? && permission == :send_messages
        computed.anybits?(Permissions::MASKS[:send_messages_in_threads])
      else
        computed.anybits?(Permissions::MASKS[permission])
      end
    end

    # Checks whether this user has a particular permission defined (i.e. not implicit, through for example Manage Roles).
    # @param permission [Symbol] The permission that should be checked. See also {Permissions::FLAGS} for a list.
    # @param channel [Channel, nil] If channel overrides should be checked too, this channel specifies where the overrides should be checked.
    # @example Check if a member has the Manage Channels permission defined in the server.
    #   has_manage_channels = member.defined_permission?(:manage_channels)
    # @return [true, false] Whether or not this user has the permission defined.
    def defined_permission?(permission, channel = nil)
      base = server.everyone_role.permissions.bits

      roles.each { |role| base |= role.permissions.bits }

      # rubocop:disable Style/IfUnlessModifier
      if channel && !channel.is_a?(Channel)
        channel = @bot.channel(channel.resolve_id)
      end

      # rubocop:enable Style/IfUnlessModifier
      computed = if channel
                   compute_overwrites(base, channel)
                 else
                   base
                 end

      computed.anybits?(Permissions::MASKS[permission])
    end

    # Define methods for querying permissions.
    Discordrb::Permissions::MASKS.each_key do |flag|
      define_method("can_#{flag}?") do |channel = nil|
        permission?(flag, channel)
      end
    end

    alias_method :can_administrate?, :can_administrator?
    alias_method :can_manage_scheduled_events?, :can_manage_events?
    alias_method :can_use_external_emojis?, :can_use_external_emoji?
    alias_method :can_manage_server_expressions?, :can_manage_emojis?
    alias_method :can_use_application_commands?, :can_use_slash_commands?

    private

    # @!visibility private
    def compute_overwrites(base, channel, implicit = nil)
      # Threads inherit the permissions of their parent.
      channel = channel.parent if channel.thread? && implicit

      if (everyone = channel.permission_overwrites[@server_id])
        base &= ~everyone.deny.bits
        base |= everyone.allow.bits
      end

      deny = 0
      allow = 0

      roles.each do |role|
        next unless (found = channel.permission_overwrites[role.id])

        deny |= found.deny.bits
        allow |= found.allow.bits
      end

      base &= ~deny
      base |= allow

      if (member_overwrite = channel.permission_overwrites[@user.id])
        base &= ~member_overwrite.deny.bits
        base |= member_overwrite.allow.bits
      end

      return base unless implicit

      hash = Permissions::IMPLICIT
      connect = Permissions::MASKS[:connect]
      view = Permissions::MASKS[:read_messages]
      send = Permissions::MASKS[:send_messages]

      if channel.text? || channel.news? || channel.thread_only?
        (base &= ~hash[:text]) if base.nobits?(view)
        (base &= ~hash[:send_messages]) if base.nobits?(send)
      elsif channel.voice?
        (base &= ~hash[:voice]) if base.nobits?(connect) || base.nobits?(view)
        (base &= ~hash[:send_messages]) if base.nobits?(send)
      elsif channel.stage?
        (base &= ~hash[:stage]) if base.nobits?(connect) || base.nobits?(view)
        (base &= ~hash[:send_messages]) if base.nobits?(send)
      end

      base
    end
  end
end
