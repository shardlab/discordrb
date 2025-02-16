# frozen_string_literal: true

module Discordrb
  module API
    # @!discord_api https://discord.com/developers/docs/resources/subscription
    module SubscriptionEndpoints
      # @!discord_api https://discord.com/developers/docs/resources/subscription#list-sku-subscriptions
      # @param sku_id [Integer, String] An ID that uniquely identifies a stock keeping unit.
      # @return [Array<Hash<Symbol, Object>>]
      def list_sku_subscriptions(sku_id, **params)
        request Route[:GET, "/skus/#{sku_id}/subscriptions"], params: params
      end

      # @!discord_api https://discord.com/developers/docs/resources/subscription#get-sku-subscription
      # @param sku_id [Integer, String] An ID that uniquely identifies a stock keeping unit.
      # @param subscription_id [Integer, String] An ID that uniquely a subscription.
      # @return [Array<Hash<Symbol, Object>>]
      def get_sku_subscription(sku_id, subscription_id, **params)
        request Route[:GET, "/skus/#{sku_id}/subscriptions/#{subscription_id}"], params: params
      end
    end
  end
end
