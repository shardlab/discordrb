# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/application
    module ApplicationEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/application#get-current-application
      # @return [Hash<Symbol, Object>]
      def get_current_application(**params)
        request Route[:GET, '/applications/@me'], params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/application#edit-current-application
      # @param custom_install_url [String] Default custom authorization for the URL.
      # @param description [String] Description of the app.
      # @param role_connections_verification_url [String] Role connection verification URL for the app.
      # @param install_params [Hash<Symbol, Object>] Settings for the app's default in-app authorization link.
      # @param integration_types_config [Hash] Hash containing supported install types.
      # @param flags [Integer] Public flags for the app.
      # @param icon [String, #read] A base64 encoded string with the image data.
      # @param cover_image [String, #read] A base64 encoded string with the image data.
      # @param interactions_endpoint_url [String] An endpoint an app can use to reccive interactions via the REST API.
      # @param tags [Array<String>] Tags that describe the functionality of the app.
      # @return [Hash<Symbol, Object>]
      def edit_current_application(custom_install_url: :undef, description: :undef,
                                   role_connections_verification_url: :undef, install_params: :undef,
                                   integration_types_config: :undef, flags: :undef, icon: :undef,
                                   cover_image: :undef, interactions_endpoint_url: :undef, tags: :undef, **rest)
        data = {
          custom_install_url: custom_install_url,
          description: description,
          role_connections_verification_url: role_connections_verification_url,
          install_params: install_params,
          integration_types_config: integration_types_config,
          flags: flags,
          icon: icon,
          cover_image: cover_image,
          interactions_endpoint_url: interactions_endpoint_url,
          tags: tags,
          **rest
        }

        request Route[:PATCH, '/applications/@me'],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/resources/application-role-connection-metadata#get-application-role-connection-metadata-records
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @return [Hash<Symbol, Object>]
      def get_application_role_connection_metadata_records(application_id, **params)
        request Route[:GET, "/applications/#{application_id}/role-connections/metadata"],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/application-role-connection-metadata#update-application-role-connection-metadata-records
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param application_role_connection_metadata [Hash<Symbol, Object>] An application role connection metadata object.
      # @return [Hash<Symbol, Object>]
      def update_application_role_connection_metadata_records(application_id, application_role_connection_metadata, **rest)
        request Route[:PUT, "/applications/#{application_id}/role-connections/metadata"],
                body: filter_undef({ application_role_connection_metadata: role_connection_metadata, **rest })
      end
    end
  end
end
