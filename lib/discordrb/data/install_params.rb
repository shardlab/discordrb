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

    # @!visibility private
    def to_h
      { scopes: @scopes.any? ? @scopes : nil, permissions: @permissions&.bits&.to_s }.compact
    end
  end
end
