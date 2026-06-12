# frozen_string_literal: true

module Discordrb
  # An emoji from a server, or a unicode one.
  class Emoji
    include IDObject

    # @return [String] the name of the emoji.
    attr_reader :name

    # @return [Array<Role>, nil] the roles that can use the emoji.
    attr_reader :roles

    # @return [Server, nil] the server the emoji is from, `nil` if unknown.
    attr_reader :server

    # @return [true, false, nil] if the emoji is managed by an integration.
    attr_reader :managed

    # @return [true, false] if the emoji is animated; usually for `gif` emojis.
    attr_reader :animated

    # @return [true, false, nil] if the emoji can be used. May be `false` due to
    #   a loss of server boosts.
    attr_reader :available

    # @return [true, false, nil] if the emoji must be wrapped in colons to be used.
    attr_reader :requires_colons

    alias_method :managed?, :managed
    alias_method :animated?, :animated
    alias_method :available?, :available
    alias_method :requires_colons?, :requires_colons

    # @!visibility private
    def initialize(data, bot, server = nil)
      @bot = bot
      @server = server
      @id = data['id']&.to_i
      @name = data['name']
      @roles = data['roles']&.filter_map { |id| server&.role(id) }
      @managed = data['managed']
      @animated = data['animated'] || false
      @available = data['available']
      @requires_colons = data['requires_colons']
      @creator = @bot.ensure_user(data['user']) if data['user']
      @application_emoji = data['_application'] if data['_application']
    end

    # Get a string that will allow the emoji to be sent as a reaction.
    # @return [String] A string that can be used to add the emoji as a reaction.
    def to_reaction
      @id ? "#{@name}:#{@id}" : @name
    end

    # Get a hash that will allow the emoji to be used in various endpoints.
    # @return [Hash] A hash that will allow the emoji to be sent in polls and buttons.
    def to_h
      @id ? { id: @id } : { name: @name }
    end

    # Get the icon URL of the emoji.
    # @param format [String, nil] The URL will default to `webp`. You can otherwise
    #   specifiy one of `png`, 'gif', or `jpeg` to override this.
    # @param size [Integer, nil] The size to render the emoji as. You can specifiy any
    #   number between 1-4096 that's a power of two.
    # @return [String, nil] The icon URL, or `nil` if the emoji is not a custom emoji.
    def url(format: 'webp', size: nil)
      API.emoji_icon_url(@id, format, size) if @id
    end

    # Get a string that will allow the emoji to be sent in a message.
    # @return [String] A string that can be used to send the emoji in a message.
    def mention
      @id ? "<#{'a' if @animated}:#{@name}:#{@id}>" : @name
    end

    # Check if the emoji is equivalent to another emoji.
    # @param other [Emoji] The other emoji to compare this one against.
    # @return [true, false] Whether or not the two objects are considered to be equal.
    def ==(other)
      return false unless other.is_a?(Discordrb::Emoji)

      @id ? Discordrb.id_compare?(@id, other) : @name == other.name
    end

    alias_method :eql?, :==
    alias_method :use, :mention
    alias_method :to_s, :mention
    alias_method :icon_url, :url

    # Get the user who uploaded the emoji to the server, or to the application.
    # @return [User, nil] The uploader of the emoji, or `nil` if it couldn't be resolved.
    def creator
      return @creator if @creator || (!@server && !@application_emoji)

      if @server.bot.can_manage_emojis? || @server.bot.can_create_server_expressions?
        update_data(JSON.parse(API::Server.get_emoji(@bot.token, @server.id, @id)))
      elsif @application_emoji
        data = API::Application.get_application_emoji(@bot.token, @bot.profile.id, @id)
        update_data(JSON.parse(data))
      end

      @creator
    end

    # Modify the properties of the emoji.
    # @param name [String] The new 2-32 character name of the emoji.
    # @param roles [Array<Role, Integer, String>, nil] The new roles that can use the
    #   emoji. This argument is always ignored for application emojis.
    # @param reason [String, nil] The reason to show in the server's audit log for modifying
    #   the emoji. This argument is always ignored for application emojis.
    # @return [nil]
    def modify(name: :undef, roles: :undef, reason: nil)
      roles = Array(roles).map(&:resolve_id) if roles != :undef && roles && !@application_emoji

      if @application_emoji && name != :undef
        update_data(JSON.parse(API::Application.edit_application_emoji(@bot.token, @bot.profile.id, @id, name)))
      elsif @server
        update_data(JSON.parse(API::Server.update_emoji(@bot.token, @server.id, @id, name:, roles:, reason:)))
      end

      nil
    end

    # Permanently delete the emoji.
    # @param reason [String, nil] The reason to show in the server's audit log for
    #   deleting the emoji. This argument is always ignored for application emojis.
    # @return [nil]
    def delete(reason: nil)
      if @application_emoji
        @bot.delete_application_emoji(@id)
      elsif @server
        API::Server.delete_emoji(@bot.token, @server.id, @id, reason)
      end

      nil
    end

    # @!visibility private
    def update_data(new_data)
      @name = new_data['name']
      @roles = new_data['roles']&.filter_map { |id| @server&.role(id) }
      @available = new_data['available']
      @creator = @bot.ensure_user(new_data['user']) if new_data['user']
    end

    # @!visibility private
    def inspect
      "<Emoji id=#{@id.inspect} name=\"#{@name}\" animated=#{@animated}>"
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
