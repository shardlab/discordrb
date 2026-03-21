# frozen_string_literal: true

module Discordrb
  # A sticker that can be sent in a message.
  class Sticker
    include IDObject

    # Map of format types.
    FORMATS = {
      png: 1,
      apng: 2,
      lottie: 3,
      gif: 4
    }.freeze

    # @return [String] the name of the sticker.
    attr_reader :name

    # @return [String] the tags of the sticker.
    attr_reader :tags

    # @return [true, false] whether the sticker can be used.
    #   This can be false due to a lack of server boosts.
    attr_reader :available
    alias_method :available?, :available

    # @return [Integer, nil] the server ID of the sticker.
    attr_reader :server_id

    # @return [Integer] the sticker's sort value in its pack.
    attr_reader :sort_value

    # @return [Integer] the type of the sticker's file.
    attr_reader :format_type

    # @return [String, nil] the description of the sticker.
    attr_reader :description

    # @!visibility private
    def initialize(data, bot, server = nil)
      @bot = bot
      @server = server
      @id = data['id'].to_i
      @name = data['name']
      @tags = data['tags']
      @type = data['type']
      @sort_value = data['sort_value'] || 0
      @format_type = data['format_type']
      @description = data['description']
      @pack_id = data['pack_id']&.to_i
      @server_id = data['guild_id']&.to_i
      @creator = bot.ensure_user(data['user']) if data['user']
      @available = official? || data['available']
    end

    # Whether this is an official sticker in a pack.
    # @return [true, false] Whether this sticker is an official sticker in a pack.
    def official?
      @type == 1
    end

    alias_method :default?, :official?

    # Whether this is a custom sticker uploaded to a server.
    # @return [true, false] Whether this sticker is a custom sticker that was uploaded to a server.
    def server?
      @type == 2
    end

    # Modify the properties of the sticker.
    # @param name [String] The new 2-30 character name of the sticker.
    # @param tags [String, Array<String>] The new tags of the sticker, max 200 characters.
    # @param description [String, nil] The new 2-100 character description of the sticker.
    # @param reason [String, nil] The reason to show in the audit log for modifying the sticker.
    # @return [nil]
    def modify(name: :undef, description: :undef, tags: :undef, reason: nil)
      raise Discordrb::Errors::NoPermission, 'You cannot update a default sticker' if official?

      data = {
        name: name,
        description: description,
        tags: tags.is_a?(Array) ? tags.join(', ') : tags,
        reason: reason
      }

      update_data(JSON.parse(API::Server.update_sticker(@bot.token, @server_id, @id, **data)))
      nil
    end

    # Get the sticker pack this sticker is associated with.
    # @return [Pack, nil] The pack this sticker is from, or `nil` if this sticker doesn't have one.
    def pack
      @bot.sticker_pack(@pack_id) if @pack_id
    end

    # Get the server this sticker is associated with.
    # @return [Server, nil] The server this sticker is associated with, or `nil` if this sticker doesn't have one.
    # @raise [Errors::NoPermission] this can happen when the bot is not in the server that is associated with the sticker.
    def server
      (@server ||= @bot.server(@server_id)) if @server_id
    end

    # Get the user who uploaded the sticker.
    # @return [User, nil] The user who uploaded the sticker, or `nil` if the creator could not be resolved.
    def creator
      return @creator if @creator || official? || @bot.servers[@server_id].nil?

      update_data(JSON.parse(API::Server.get_sticker(@bot.token, @server_id, @id)))

      @creator
    end

    # Delete the sticker. Use this with caution, as it cannot be undone!
    # @param reason [String, nil] The audit log reason for deleting this sticker.
    # @return [nil]
    def delete(reason: nil)
      raise 'cannot delete an official sticker' if official?

      API::Server.delete_sticker(@bot.token, @server_id, @id, reason: reason)
      @server&.delete_sticker(@id)
      nil
    end

    # Get the extension that can be used to access the sticker's URL.
    # @return ['png', 'json', 'gif'] The file extension of the sticker.
    def extension
      if png? || apng?
        'png'
      elsif lottie?
        'json'
      elsif gif?
        'gif'
      end
    end

    # Utility method to get a sticker's CDN URL.
    # @param query [true, false] Whether or not to append
    #   the size query parameter for `gif` stickers.
    # @return [String] The CDN URL to the sticker's file.
    def url(query: true)
      url = API.sticker_url(@id, extension)

      gif? && query ? ("#{url}?size=4096") : url
    end

    # @!method png?
    #   @return [true, false] whether or not the sticker is a PNG file.
    # @!method apng?
    #   @return [true, false] whether or not the sticker is an animated APNG file.
    # @!method lottie?
    #   @return [true, false] whether or not the sticker is a lottie JSON file.
    # @!method gif?
    #   @return [true, false] whether or not the sticker is an animated GIF file.
    FORMATS.each do |name, value|
      define_method("#{name}?") do
        @format_type == value
      end
    end

    # @!visibility private
    def update_data(new_data)
      @name = new_data['name']
      @tags = new_data['tags']
      @description = new_data['description']
      @creator = @bot.ensure_user(new_data['user']) if new_data['user']
      @available = new_data.key?('available') ? new_data['available'] : true
    end

    # @!visibility private
    def inspect
      "<Sticker id=#{@id} name=\"#{@name}\" tags=\"#{@tags}\" description=\"#{@description}\">"
    end

    # A pack of official stickers that everyone can use.
    class Pack
      include IDObject

      # @return [String] the name of the sticker pack.
      attr_reader :name

      # @return [Integer] the ID of the sticker pack's SKU.
      attr_reader :sku_id

      # @return [Array<Sticker>] the stickers in the sticker pack.
      attr_reader :stickers

      # @return [String, nil] the hash to the sticker pack's banner image.
      attr_reader :banner_id

      # @return [String] the description of the sticker pack shown in the store.
      attr_reader :description

      # @return [Sticker, nil] the sticker that's shown on the sticker pack's icon.
      attr_reader :cover_sticker

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id'].to_i
        @name = data['name']
        @sku_id = data['sku_id'].to_i
        @banner_id = data['banner_asset_id']
        @description = data['description']
        @stickers = data['stickers'].map { |sticker| @bot.ensure_sticker(sticker) }
        @cover_sticker = @stickers.find { |sticker| sticker.id == data['cover_sticker_id']&.to_i }
      end

      # Utility method to get a sticker pack's banner URL.
      # @param format [String] The URL will default to `webp`. You can otherwise specify one of `webp`, `jpg` or `png` to override this.
      # @param size [Integer, nil] The URL will default to `4096`. You can otherwise specify any number that's a power of two to override this.
      # @return [String, nil] The URL to the sticker pack's banner image, or `nil` if the sticker pack doesn't have an associated banner image.
      def banner_url(format: 'webp', size: 4096)
        API.sticker_pack_banner_url(@banner_id, format, size) if @banner_id
      end

      # @!visibility private
      def inspect
        "<Sticker::Pack id=#{@id} name=\"#{@name}\" description=\"#{@description}\" banner_id=#{@banner_id}>"
      end
    end

    # The smallest amount of data required to render a sticker.
    class Item
      include IDObject

      # @return [String] the name of the sticker item.
      attr_reader :name

      # @return [Integer] the format type of the sticker item.
      attr_reader :format_type

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @id = data['id'].to_i
        @name = data['name']
        @format_type = data['format_type']
      end

      # @!method png?
      #   @return [true, false] whether or not the sticker item is a PNG file.
      # @!method apng?
      #   @return [true, false] whether or not the sticker item is an animated APNG file.
      # @!method lottie?
      #   @return [true, false] whether or not the sticker item is a lottie JSON file.
      # @!method gif?
      #   @return [true, false] whether or not the sticker item is an animated GIF file.
      FORMATS.each do |name, value|
        define_method("#{name}?") do
          @format_type == value
        end
      end

      # Get the extension that can be used to access the sticker's URL.
      # @return ['png', 'json', 'gif'] The file extension of the sticker.
      def extension
        if png? || apng?
          'png'
        elsif lottie?
          'json'
        elsif gif?
          'gif'
        end
      end

      # Utility method to get a sticker item's CDN URL.
      # @param query [true, false] Whether or not to append the
      #   size query parameter for `gif` sticker items.
      # @return [String] The CDN URL to the sticker item's file.
      def url(query: true)
        url = API.sticker_url(@id, extension)

        gif? && query ? ("#{url}?size=4096") : url
      end

      # Convert this sticker item into a full sticker object.
      # @return [Sticker, nil] The full sticker object, or `nil` if the sticker was deleted.
      def to_sticker
        @bot.sticker(@id)
      end

      # @!visibility private
      def inspect
        "<Sticker::Item id=#{@id} name=\"#{@name}\" format_type=#{@format_type}>"
      end
    end
  end
end
