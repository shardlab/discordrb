# frozen_string_literal: true

module Discordrb
  # Information about a bot's associated application.
  class Application
    include IDObject

    # Map of application flags.
    FLAGS = {
      automod_rule_badge: 1 << 6,
      approved_presence_intent: 1 << 12,
      limited_presence_intent: 1 << 13,
      approved_server_members_intent: 1 << 14,
      limited_server_members_intent: 1 << 15,
      pending_server_limit_verification: 1 << 16,
      embedded: 1 << 17,
      approved_message_content_intent: 1 << 18,
      limited_message_content_intent: 1 << 19,
      application_command_badge: 1 << 23
    }.freeze

    # @return [String] the application's name.
    attr_reader :name

    # @return [String] the application's description, or an empty string if the application doesn't have a description.
    attr_reader :description

    # @return [Array<String>] the application's origins permitted to use RPC.
    attr_reader :rpc_origins

    # @return [Integer] the application's public flags.
    attr_reader :flags

    # @return [User, nil] the user that owns the application, or nil if the application belongs to a team.
    attr_reader :owner

    # @return [String, nil] the ID of the application's icon. Can be used to generate an icon URL.
    # @see #icon_url
    attr_reader :icon_id

    # @return [true, false] if users other than the bot owner can add the bot to servers.
    attr_reader :public
    alias_method :public?, :public

    # @return [true, false] whether the bot requires the full OAuth2 code grant in order to join servers.
    attr_reader :requires_code_grant
    alias_method :requires_code_grant?, :requires_code_grant

    # @return [String, nil] the URL to the application's terms of service.
    attr_reader :terms_of_service_url

    # @return [String, nil] the URL to the application's privacy policy.
    attr_reader :privacy_policy_url

    # @return [String] the hex encoded key for verification in interactions and the GameSDK.
    attr_reader :verify_key

    # @return [Team, nil] the team that owns this application, or `nil` if the application isn't owned by a team.
    attr_reader :team

    # @return [Integer, nil] the ID of the server that is associated with this application.
    attr_reader :server_id

    # @return [String, nil] the URL slug that links to the application's game store page.
    attr_reader :slug

    # @return [Integer, nil] the game SKU ID if this application is a game sold on Discord.
    attr_reader :primary_sku_id

    # @return [String, nil] the ID of the application's default rich presence invite cover image.
    #   Can be used to generate a cover image URL.
    # @see #cover_image_url
    attr_reader :cover_image_id

    # @return [Integer] the approximate amount of server's the application has been added to.
    attr_reader :server_install_count

    # @return [Integer] the approximate amount of users that have installed the application with the
    #   `application.commands` oauth scope.
    attr_reader :user_install_count

    # @return [Integer] the approximate amount of users that have OAuth2 authorizations for the application.
    attr_reader :user_authorization_count

    # @return [Array<String>] an array of redirect URIs for the application.
    attr_reader :redirect_uris
    alias_method :redirect_urls, :redirect_uris

    # @return [String, nil] the interactions endpoint URL for the application.
    attr_reader :interactions_endpoint_url

    # @return [String, nil] the role connections URL for the application.
    attr_reader :role_connections_verification_url

    # @return [String, nil] the webhook events URL used by the application to receive webhook events.
    attr_reader :webhook_events_url

    # @return [Integer] the status of the application's webhook events.
    attr_reader :webhook_events_status

    # @return [Array<String>] the webhook event types that the application is subscribed to.
    attr_reader :webhook_event_types

    # @return [Array<String>] an array of traits describing the content and functionality of the application.
    attr_reader :tags

    # @return [InstallParams] the settings for the application's default authorization link.
    attr_reader :install_params

    # @return [Hash<Integer => InstallParams>] the default scopes and permissions for each supported installation context.
    attr_reader :integration_types

    # @return [String, nil] the default custom authorization URL for the application.
    attr_reader :custom_install_url

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      update_data(data)
    end

    # Get the server associated with this application.
    # @return [Server, nil] This will be nil if the bot does not have an associated server set.
    # @raise [Discordrb::Errors::NoPermission] This can happen when the bot is not in the associated server.
    def server
      @bot.server(@server_id) if @server_id
    end

    # Utility method to get a application's icon URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `webp`, `jpg` or `png` to override this.
    # @return [String, nil] The URL of the icon image (`nil` if no image is set).
    def icon_url(format: 'webp')
      API.app_icon_url(@id, @icon_id, format) if @icon_id
    end

    # Utility method to get a application's cover image URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `webp`, `jpg` or `png` to override this.
    # @return [String, nil] The URL of the cover image (`nil` if no cover is set).
    def cover_image_url(format: 'webp')
      API.app_cover_url(@id, @cover_image_id, format) if @cover_image_id
    end

    # Delete an integration types config for the application.
    # @param type [Integer, String] The type of the integration type to remove.
    def delete_integration_type(type)
      new_data = @integration_types.dup.tap { |i| i.delete(type.to_i) }
      modify(integration_types: collect_integration_types(new_data))
    end

    # Add an integration types config for the application.
    # @param type [Integer, String] The type of the integration type.
    # @param scopes [Array<String, Symbol>, nil] The default Oauth scopes for the config.
    # @param permissions [Permissions, String, Integer, nil] The default permissions for the config.
    def add_integration_type(type:, scopes: nil, permissions: nil)
      permissions = permisisons.bits if permissions.respond_to?(:bits)
      new_data = @integration_types.dup

      new_data[type.to_i] = {
        scopes: scopes&.map(&:to_s),
        permissions: permissions&.to_s
      }

      modify(integration_types: collect_integration_types(new_data.compact))
    end

    # Get the integration types config for when the application has been installed to a user.
    # @return [InstallParams, nil] The default install params for when the application's is installed to a user.
    def user_integration_type
      @integration_type[1]
    end

    # Get the integration types config for when the application has been installed in a server.
    # @return [InstallParams, nil] The defaults install params for when the application's is installed in a server.
    def server_integration_type
      @integration_types[0]
    end

    # Modify the properties of the application.
    # @param icon [#read, nil] The new icon for the application. Must be a file-like object that response to `#read`.
    # @param cover_image [#read, nil] The new rich presence cover image for the application. Must be a file-like object that response to `#read`.
    # @param flags [Integer, Symbol, Array<Symbol, Integer>] The new flags to set for the application. Only limited intent flags can be updated.
    # @param tags [Array<String, Symbol>, nil] The new tags representing the application's traits.
    # @param description [String, nil] The new description of the application.
    # @param custom_install_url [String, nil] The new default custom authorization URL for the application.
    # @param webhook_events_url [String, nil] The new URL the application will use to receive webhook events via HTTP.
    # @param webhook_events_status [Integer] The new status of the application's webhook events.
    # @param webhook_event_types [Array<String, Symbol>, nil] The new types of webhook events that the application wishes to receive.
    # @param interactions_endpoint_url [String, nil] The new URL the application will use to receive INTERACTION_CREATE events via HTTP.
    # @param install_scopes [Array<String, Symbol>] The new default scopes to add the application to a server with.
    # @param install_permissions [Permissions, Integer, String] The new default permissions to add the application to a server with.
    # @param role_connections_verification_url [String, nil] The new role connections verification URL for the application.
    # @param add_flags [Integer, Symbol, Array<Symbol, Integer>] The limited intent flags to add to the application.
    # @param remove_flags [Integer, Symbol, Array<Symbol, Integer>] The limited intent flags to remove from the application.
    # @param integration_types [#to_h] The new integration types configuration for the application.
    # @note When using the `add_flags:` and `remove_flags:` parameters, The flags are removed first, and then added.
    # @return [nil]
    def modify(
      icon: :undef, cover_image: :undef, flags: :undef, tags: :undef, description: :undef,
      custom_install_url: :undef, webhook_events_url: :undef, webhook_events_status: :undef,
      webhook_event_types: :undef, interactions_endpoint_url: :undef, install_scopes: :undef,
      install_permissions: :undef, role_connections_verification_url: :undef, add_flags: :undef,
      remove_flags: :undef, integration_types: :undef
    )
      data = {
        icon: icon.respond_to?(:read) ? Discordrb.encode64(icon) : icon,
        cover_image: cover_image.respond_to?(:read) ? Discordrb.encode64(cover_image) : cover_image,
        flags: flags == :undef ? flags : [*flags].map { |bit| FLAGS[bit] || bit.to_i }.reduce(&:|),
        tags: tags,
        description: description,
        custom_install_url: custom_install_url,
        event_webhooks_url: webhook_events_url || '',
        event_webhooks_status: webhook_events_status,
        event_webhooks_types: webhook_event_types || [],
        interactions_endpoint_url: interactions_endpoint_url,
        role_connections_verification_url: role_connections_verification_url,
        integration_types_config: integration_types == :undef ? integration_types : integration_types&.to_h
      }

      ((data[:install_params] ||= @install_params.to_h)[:scopes] = install_scopes) if install_scopes != :undef

      if install_permissions != :undef
        install_permissions = install_permissions.bits if install_permissions.respond_to?(:bits)
        (data[:install_params] ||= @install_params.to_h)[:permissions] = install_permissions.to_s
      end

      if add_flags != :undef || remove_flags != :undef
        raise ArgumentError, "'add_flags' and 'remove_flags' are mutually exclusive with 'flags'" if flags != :undef

        to_flags = lambda do |value|
          [*(value == :undef ? 0 : value)].map { |bit| FLAGS[bit] || bit.to_i }.reduce(&:|)
        end

        data[:flags] = ((@flags & ~to_flags.call(remove_flags)) | to_flags.call(add_flags))
      end

      update_data(JSON.parse(API::Application.update_current_application(@bot.token, **data)))
      nil
    end

    # @!method automod_rule_badge?
    #   @return [true, false] whether or not the application has at least 100 automod rules across all of its servers.
    # @!method approved_presence_intent?
    #   @return [true, false] whether or not the application is in less than 100 servers and has access to the server presences intent.
    # @!method limited_presence_intent?
    #   @return [true, false] whether or not the application is in more than 100 servers and has access to the server presences intent.
    # @!method approved_server_members_intent?
    #   @return [true, false] whether or not the application is in more than 100 servers and has access to the server members intent.
    # @!method limited_server_members_intent?
    #   @return [true, false] whether or not the application is in less than 100 servers and has access to the server members intent.
    # @!method pending_server_limit_verification?
    #   @return [true, false] whether or not the application has underwent unusual growth that is preventing it from being verified.
    # @!method embedded?
    #   @return [true, false] whether or not the application is embedded within the Discord application (currently unavailable publicly).
    # @!method approved_message_content_intent?
    #   @return [true, false] whether or not the application is in more than 100 servers and has access to the message content intent.
    # @!method limited_message_content_intent?
    #   @return [true, false] whether or not the application is in less than 100 servers and has access to the message content intent.
    # @!method application_command_badge?
    #   @return [true, false] whether or not the application has registered at least one global application command.
    FLAGS.each do |name, value|
      define_method("#{name}?") do
        @flags.anybits?(value)
      end
    end

    # Check if the application has the presence intent toggled on its dashboard.
    # @return [true, false] Whether or not the application has access to the presence intent.
    def presence_intent?
      approved_presence_intent? || limited_presence_intent?
    end

    # Check if the application has the server members intent toggled on its dashboard.
    # @return [true, false] Whether or not the application has access to the server members intent.
    def server_members_intent?
      approved_server_members_intent? || limited_server_members_intent?
    end

    # Check if the application has the message content intent toggled on its dashboard.
    # @return [true, false] Whether or not the application has access to the message content intent.
    def message_content_intent?
      approved_message_content_intent? || limited_message_content_intent?
    end

    # @!visibility private
    def inspect
      "<Application name=#{@name} id=#{@id} public=#{@public} tags=#{@tags} flags=#{@flags}>"
    end

    private

    # @!visibility private
    def update_data(new_data)
      @name = new_data['name']
      @description = new_data['description']
      @icon_id = new_data['icon']
      @rpc_origins = new_data['rpc_origins'] || []
      @flags = new_data['flags'] || 0
      @owner = new_data['owner'] ? @bot.ensure_user(new_data['owner']) : nil

      @public = new_data['bot_public']
      @requires_code_grant = new_data['bot_require_code_grant']
      @terms_of_service_url = new_data['terms_of_service_url']
      @privacy_policy_url = new_data['privacy_policy_url']
      @verify_key = new_data['verify_key']
      @team = new_data['team'] ? Team.new(new_data['team'], @bot) : nil

      @server_id = new_data['guild_id']&.to_i
      @cover_image_id = new_data['cover_image']
      @slug = new_data['slug']
      @primary_sku_id = new_data['primary_sku_id']&.to_i
      @server_install_count = new_data['approximate_guild_count'] || 0
      @user_install_count = new_data['approximate_user_install_count'] || 0
      @user_authorization_count = new_data['approximate_user_authorization_count'] || 0

      @redirect_uris = new_data['redirect_uris'] || []
      @interactions_endpoint_url = new_data['interactions_endpoint_url']
      @role_connections_verification_url = new_data['role_connections_verification_url']
      @webhook_events_url = new_data['event_webhooks_url']
      @webhook_events_status = new_data['event_webhooks_status']

      @webhook_event_types = new_data['event_webhooks_types'] || []
      @tags = new_data['tags'] || []
      @install_params = InstallParams.new(new_data['install_params'] || {}, @bot)
      @custom_install_url = new_data['custom_install_url']

      @integration_types = (new_data['integration_types_config'] || {}).to_h do |key, value|
        [key.to_i, InstallParams.new(value['oauth2_install_params'] || {}, @bot)]
      end
    end

    # @!visibility private
    def collect_integration_types(integration_types)
      integration_types.each_with_object({}) do |(key, value), result|
        result[key.to_s] = value.to_h.any? ? { oauth2_install_params: value.to_h } : {}
      end
    end
  end
end
