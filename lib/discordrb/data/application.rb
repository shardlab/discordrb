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

    # @return [Team, nil] the team that owns the application, or `nil` if the application isn't owned by a team.
    attr_reader :team

    # @return [Integer, nil] the ID of the server that is associated with the application.
    attr_reader :server_id

    # @return [String, nil] the URL slug that links to the application's game store page.
    attr_reader :slug

    # @return [Integer, nil] the game SKU ID if the application is a game sold on Discord.
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

    # @return [String, nil] the default custom authorization URL for the application.
    attr_reader :custom_install_url

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      update_data(data)
    end

    # Get the server associated with the application.
    # @return [Server, nil] This will be `nil` if the bot does not have an associated server set.
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
    # @param type [Integer, Symbol] The type of the integration type to remove.
    # @return [nil]
    def delete_integration_type(type)
      type = Interaction::INTEGRATION_TYPES[type.to_sym] if type.respond_to?(:to_sym)

      integration_types = @integration_types.dup.tap do |integration_type|
        integration_type.delete(type)
      end

      modify(integration_types: collect_integration_types(integration_types))
    end

    # Add or update an integration types config for the application.
    # @param type [Integer, Symbol] The type of the integration type to upsert.
    # @param scopes [Array<String, Symbol>, nil] The default Oauth scopes for the config.
    # @param permissions [Permissions, String, Integer, nil] The default permissions for the config.
    # @return [nil]
    def modify_integration_type(type:, scopes: :undef, permissions: :undef)
      permissions = permissions.bits if permissions.respond_to?(:bits)
      type = Interaction::INTEGRATION_TYPES[type.to_sym] if type.respond_to?(:to_sym)

      integration_types = @integration_types.dup

      integration_types[type] = {
        scopes: scopes == :undef ? (integration_types[type]&.scopes || []) : scopes,
        permissions: (permissions == :undef ? (integration_types[type]&.permissions&.bits || 0) : permissions)&.to_s
      }

      modify(integration_types: collect_integration_types(integration_types))
    end

    # Get the integration types config for when the application has been installed to a user.
    # @return [InstallParams, nil] The default install params for when the application is installed to a user.
    def user_integration_type
      @integration_types[1]
    end

    # Get the integration types config for when the application has been installed in a server.
    # @return [InstallParams, nil] The defaults install params for when the application is installed in a server.
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
    # @param role_connections_verification_url [String, nil] The new role connections verification URL for the application.
    # @param add_flags [Integer, Symbol, Array<Symbol, Integer>] The limited intent flags to add to the application.
    # @param remove_flags [Integer, Symbol, Array<Symbol, Integer>] The limited intent flags to remove from the application.
    # @note When using the `add_flags:` and `remove_flags:` parameters, The flags are removed first, and then added.
    # @return [nil]
    def modify(
      icon: :undef, cover_image: :undef, flags: :undef, tags: :undef, description: :undef,
      custom_install_url: :undef, webhook_events_url: :undef, webhook_events_status: :undef,
      webhook_event_types: :undef, interactions_endpoint_url: :undef, integration_types: :undef,
      role_connections_verification_url: :undef, add_flags: :undef, remove_flags: :undef
    )
      data = {
        icon: icon.respond_to?(:read) ? Discordrb.encode64(icon) : icon,
        cover_image: cover_image.respond_to?(:read) ? Discordrb.encode64(cover_image) : cover_image,
        flags: flags == :undef ? flags : [*flags].reduce(0) { |sum, bit| sum | (FLAGS[bit] || bit.to_i) },
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

      if add_flags != :undef || remove_flags != :undef
        raise ArgumentError, "'add_flags' and 'remove_flags' are mutually exclusive with 'flags'" if flags != :undef

        to_flags = lambda do |bits|
          bits == :undef ? 0 : [*bits].reduce(0) { |sum, bit| sum | (FLAGS[bit] || bit.to_i) }
        end

        data[:flags] = ((@flags & ~to_flags.call(remove_flags)) | to_flags.call(add_flags))
      end

      update_data(JSON.parse(API::Application.update_current_application(@bot.token, **data)))
      nil
    end

    # @!method automod_rule_badge?
    #   @return [true, false] whether or not the application has at least 100 automod rules across all of its servers.
    # @!method approved_presence_intent?
    #   @return [true, false] whether or not the application has reached more than 10,000 unique users and has access to the server presences intent.
    # @!method limited_presence_intent?
    #   @return [true, false] whether or not the application has reached less than 10,000 unique users and has access to the server presences intent.
    # @!method approved_server_members_intent?
    #   @return [true, false] whether or not the application has reached more than 10,000 unique users and has access to the server members intent.
    # @!method limited_server_members_intent?
    #   @return [true, false] whether or not the application has reached less than 10,000 unique users and has access to the server members intent.
    # @!method pending_server_limit_verification?
    #   @return [true, false] whether or not the application has underwent unusual growth that is preventing it from being verified.
    # @!method embedded?
    #   @return [true, false] whether or not the application is embedded within the Discord application (currently unavailable publicly).
    # @!method approved_message_content_intent?
    #   @return [true, false] whether or not the application has reached more than 10,000 unique users and has access to the message content intent.
    # @!method limited_message_content_intent?
    #   @return [true, false] whether or not the application has reached less than 10,000 unique users and has access to the message content intent.
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
      "<Application id=#{@id} name=\"#{@name}\" public=#{@public} flags=#{@flags}>"
    end

    private

    # @!visibility private
    def update_data(new_data)
      @name = new_data['name']
      @description = new_data['description']
      @icon_id = new_data['icon']
      @rpc_origins = new_data['rpc_origins'] || []
      @flags = new_data['flags_new'].to_i
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
      @webhook_events_status = new_data['event_webhooks_status'] || 1

      @webhook_event_types = new_data['event_webhooks_types'] || []
      @tags = new_data['tags'] || []
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
