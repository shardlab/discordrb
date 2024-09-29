# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/entitlement
    module EntitlementEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/entitlement#list-entitlements
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @return [Array<Hash<Symbol, Object>>]
      def list_entitlements(application_id, **params)
        request Route[:GET, "/applications/#{application_id}/entitlements", application_id],
                params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/entitlement#consume-an-entitlement
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param entitlement_id [Integer, String] An ID that uniquely identifies an entitlement.
      # @return [Array<Hash<Symbol, Object>>]
      def consume_an_entitlement(application_id, entitlement_id, **rest)
        request Route[:POST, "/applications/#{application_id}/entitlements/#{entitlement_id}", application_id],
                body: filter_undef(**rest)
      end

      # @!discord_api https://discord.com/developers/docs/resources/entitlement#create-test-entitlement
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param sku_id [Integer, String] An ID that uniquely identifies a SKU.
      # @param owner_id [Integer, String] The ID of the user or guild to grant this entitlement to.
      # @param owner_type [1, 2] The type of entitlement to create.
      # @return [Array<Hash<Symbol, Object>>]
      def create_test_entitlement(application_id, sku_id:, owner_id:, owner_type:, **rest)
        data = {
          sku_id: sku_id,
          owner_id: owner_id,
          owner_type: owner_type, 
          **rest
        }

        request Route[:POST, "/applications/#{application_id}/entitlements", application_id],
                body: filter_undef(data)
      end

      # @!discord_api https://discord.com/developers/docs/resources/entitlement#delete-test-entitlement
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @param entitlement_id [Integer, String] An ID that uniquely identifies an entitlement.
      # @return [nil]
      def delete_test_entitlement(application_id, entitlement_id)
        request Route[:DELETE, "/applications/#{application_id}/entitlements/#{entitlement_id}"],
      end
    end
  end
end