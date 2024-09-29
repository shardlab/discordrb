# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/sku
    module SkuEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/sku#list-skus
      # @param application_id [Integer, String] An ID that uniquely identifies an application.
      # @return [Array<Hash<Symbol, Object>>]
      def list_skus(application_id, **params)
        request Route[:GET, "/applications/#{application_id}/skus", application_id],
                params: params
      end
    end
  end
end
