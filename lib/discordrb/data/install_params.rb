# frozen_string_literal: true

module Discordrb
  # Default installation parameters for an application.
  class InstallParams
    # @return [Array<String>] the default scopes to add an application to a server with.
    attr_reader :scopes

    # @return [Permissions, nil] the default permissions to add an application to a server with.
    attr_reader :permissions

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @scopes = data['scopes'] || []
      @permissions = data['permissions'] ? Permissions.new(data['permissions']) : nil
    end

    # Check if two install params are equivalent.
    # @param other [InstallParams, Object] The object to compare against.
    # @return [true, false] Whether or not the two objects are equivalent.
    def ==(other)
      return false unless other.is_a?(InstallParams)

      @scopes == other.scopes && @permissions == other.permissions
    end

    alias_method :eql?, :==

    # @!visibility private
    def to_h
      { scopes: @scopes.any? ? @scopes : nil, permissions: @permissions&.bits&.to_s }.compact
    end
  end
end
