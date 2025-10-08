# frozen_string_literal: true

module Discordrb
  # A snapshot of a server.
  class ServerTemplate
    # @return [String] the code of the template.
    attr_reader :code
    alias_method :to_s, :code

    # @return [String] the name of the template.
    attr_reader :name

    # @return [User] the user who created the template.
    attr_reader :creator

    # @return [Time] the time at when the snapshot was last synced.
    attr_reader :synced_at

    # @return [Time] the time at when the template's source was created.
    attr_reader :created_at

    # @return [Integer] the total amount of times the template has been used.
    attr_reader :usage_count

    # @return [String, nil] the description of the template (0-120 characters).
    attr_reader :description

    # @return [SourceServer] a partial copy of the server object the template is for.
    attr_reader :source_server

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @code = data['code']
      @server_id = data['source_guild_id'].to_i
      @creator = bot.ensure_user(data['creator'])
      @created_at = Time.parse(data['created_at'])
      from_other(data)
    end

    # @return [true, false] whether or not the template
    #   doesn't have any unsynced changes with the source server.
    def synced?
      @unsynced == false
    end

    # @return [String] A link that can be used to create a new
    #   server based off of this template.
    def link
      "https://discord.new/#{@code}"
    end

    # Set the name of this template to something new.
    # @param name [String] The new 1-100 character name of this template.
    def name=(name)
      update_data(name: name)
    end

    # Set the description of this template to something new.
    # @param description [String, nil] The new 1-120 character description of this template.
    def description=(description)
      update_data(description: description)
    end

    # Sync this template to match the source server.
    # @return [void]
    def sync
      from_other(JSON.parse(API::Server.sync_template(@bot.token, @server_id, @code)))
    end

    # Delete this template. This action is irreversible and cannot be undone.
    # @return [void]
    def delete
      from_other(JSON.parse(API::Server.delete_template(@bot.token, @server_id, @code)))
    end

    private

    # @!visibility private
    def from_other(new_data)
      @name = new_data['name']
      @description = new_data['description']
      @usage_count = new_data['usage_count']
      @unsynced = new_data['is_dirty'] || false
      @synced_at = Time.parse(new_data['updated_at'])
      @source_server = SourceServer.new(new_data['serialized_source_guild'], @bot)
    end

    # @!visibility private
    def update_data(new_data)
      from_other(JSON.parse(API::Server.update_template(@bot.token, @server_id, @code, **new_data)))
    end

    # The snapshot of a template's server.
    class SourceServer
      include ServerAttributes

      # @return [Array<Role>] an array of all the roles created on this server.
      attr_reader :roles

      # @return [String] the preferred locale of the server, used in the discovery tab.
      attr_reader :locale

      # @return [Array<Channel>] an array of all the channels (text and voice) on this server.
      attr_reader :channels

      # @return [String, nil] the description of this server snapshot, shown in the discovery tab.
      attr_reader :description

      # @return [Integer] the amount of time after which a voice user gets moved into the AFK channel.
      attr_reader :afk_timeout

      # @return [Integer] the flags that have been set for the server's system channel combined as a bitfield.
      attr_reader :system_channel_flags

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @name = data['name']
        @roles = data['roles'].map { |role| Role.new(role, bot) }
        @icon_id = data['icon_hash']
        @locale = data['preferred_locale']
        @channels = data['channels'].map { |channel| Channel.new(channel, bot) }
        @description = data['description']
        @afk_timeout = data['afk_timeout']
        @afk_channel_id = data['afk_channel_id']&.to_i
        @verification_level = data['verification_level']
        @system_channel_id = data['system_channel_id']&.to_i
        @system_channel_flags = data['system_channel_flags'] || 0
        @explicit_content_filter = data['explicit_content_filter']
        @default_message_notifications = data['default_message_notifications']
      end

      # @return [Symbol] the verification level of the server.
      def verification_level
        Discordrb::Server::VERIFICATION_LEVELS.key(@verification_level)
      end

      # @return [Symbol] the explicit content filter level of the server.
      def explicit_content_filter
        Discordrb::Server::FILTER_LEVELS.key(@explicit_content_filter)
      end

      # @return [Symbol] the default message notifications settings of the server.
      def default_message_notifications
        Discordrb::Server::NOTIFICATION_LEVELS.key(@default_message_notifications)
      end

      # @return [Channel, nil] the AFK voice channel of this server, or `nil` if none is set.
      def afk_channel
        @channels.find { |channel| channel.id == @afk_channel_id } if @afk_channel_id
      end

      # @return [Channel, nil] the system channel used for automatic welcome messages of a server,
      #   or `nil` if none is set.
      def system_channel
        @channels.find { |channel| channel.id == @system_channel_id } if @system_channel_id
      end
    end
  end
end
