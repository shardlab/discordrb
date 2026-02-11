# frozen_string_literal: true

module Discordrb
  # Server emoji
  class Emoji
    include IDObject

    # @return [String] the emoji name
    attr_reader :name

    # @return [Server, nil] the server of this emoji
    attr_reader :server

    # @return [Array<Role>, nil] roles this emoji is active for, or nil if the emoji's server is unknown
    attr_reader :roles

    # @return [User, nil] the user who uploaded this emoji, or nil if the emoji's server is unknown
    attr_reader :creator

    # @return [Boolean, nil] if the emoji requires colons to be used, or nil if the emoji's server is unknown
    attr_reader :requires_colons
    alias_method :requires_colons?, :requires_colons

    # @return [Boolean, nil] whether this emoji is managed by an integration, or nil if the emoji's server is unknown
    attr_reader :managed
    alias_method :managed?, :managed

    # @return [Boolean, nil] if this emoji is currently usable, or nil if the emoji's server is unknown
    attr_reader :available
    alias_method :available?, :available

    # @return [true, false] if the emoji is animated
    attr_reader :animated
    alias_method :animated?, :animated

    # @!visibility private
    def initialize(data, bot, server = nil)
      @bot = bot
      @roles = nil

      @name = data['name']
      @server = server
      @id = data['id']&.to_i
      @animated = data['animated'] || false
      @managed = data['managed']
      @available = data['available']
      @requires_colons = data['require_colons']
      @creator = data['user'] ? bot.ensure_user(data['user']) : nil

      process_roles(data['roles']) if server
    end

    # ID or name based comparison
    def ==(other)
      return false unless other.is_a? Emoji
      return Discordrb.id_compare?(@id, other) if @id

      name == other.name
    end

    alias_method :eql?, :==

    # @return [String] the layout to mention it (or have it used) in a message
    def mention
      return name if id.nil?

      "<#{'a' if animated}:#{name}:#{id}>"
    end

    alias_method :use, :mention
    alias_method :to_s, :mention

    # @return [String] the layout to use this emoji in a reaction
    def to_reaction
      return name if id.nil?

      "#{name}:#{id}"
    end

    # Get the CDN URL for this emoji.
    # @param format [String, nil] If `nil`, the URL will default to `webp` for static emoji, and will detect if the user has a `gif` avatar.
    #   You can otherwise specify one of `webp`, `jpg`, `png`, or `gif` to override this; Discord will not return a gif form of static emoji.
    # @param size [Integer, nil] If `nil`, no size will be specified in the URL. You can otherwise specify any power of 2 from 16 to 4096.
    # @return [String] the icon URL of the emoji
    def icon_url(format: nil, size: nil)
      format ||= if animated
                   'gif'
                 else
                   'webp'
                 end
      API.emoji_icon_url(id, format, size: size)
    end

    # The inspect method is overwritten to give more useful output
    def inspect
      "<Emoji name=#{name.inspect} id=#{id.inspect} animated=#{animated}>"
    end

    # Converts this Emoji into a hash that can be sent back to Discord in other endpoints.
    # @return [Hash] A hash representation of this emoji.
    def to_h
      id.nil? ? { name: name } : { id: id }
    end

    # @!visibility private
    def process_roles(roles)
      @roles = []
      return unless roles

      roles.each do |role_id|
        role = server.role(role_id)
        @roles << role
      end
    end

    # @!visibility private
    def self.build_emoji_hash(emoji, prefix: true)
      data = { id: nil, name: nil }

      case emoji
      when Emoji, Reaction
        emoji.id ? data[:id] = emoji.id : data[:name] = emoji.name
      when Integer, String
        emoji.to_i.zero? ? data[:name] = emoji : data[:id] = emoji
      else
        raise TypeError, "Invalid emoji type: #{emoji.class}" unless emoji.nil?
      end

      prefix ? data.transform_keys!({ id: :emoji_id, name: :emoji_name }) : data
    end
  end
end
