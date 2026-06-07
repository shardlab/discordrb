# frozen_string_literal: true

module Discordrb
  # Metadata about a purchase or renewal for a role subscription.
  class RoleSubscriptionData
    # @return [String] the name of the tier the user is subscribed to.
    attr_reader :tier_name

    # @return [Integer] the ID of the SKU and listing the user is subscribed to.
    attr_reader :listing_id

    # @return [true, false] whether the subscription notification is for a renewal.
    attr_reader :renewal
    alias_method :renewal?, :renewal

    # @return [Integer] the total number of months the user has been subscribed for.
    attr_reader :total_months_subscribed

    # @!visibility private
    def initialize(data, message, bot)
      @bot = bot
      @message = message
      @renewal = data['is_renewal']
      @tier_name = data['tier_name']
      @listing_id = data['role_subscription_listing_id']&.to_i
      @total_months_subscribed = data['total_months_subscribed']
    end

    # Check if this role subscription is a new purchase.
    # @return [true, false] if this role subscription is a new purchase.
    def new?
      @renewal == false
    end

    # Get the role associated with the notification for this subscription.
    # @return [Role, nil] the role that's associated with this subscription.
    def role
      @message.server.roles.find { |role| role.tags&.subscription_listing_id == @listing_id }
    end
  end
end
