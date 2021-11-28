# frozen_string_literal: true

require 'discordrb/events/generic'
require 'discordrb/data'

module Discordrb::Events
  # Raised when a role is created on a guild
  class GuildRoleCreateEvent < Event
    # @return [Role] the role that got created
    attr_reader :role

    # @return [Guild] the guild on which a role got created
    attr_reader :guild

    # @!attribute [r] name
    #   @return [String] this role's name
    #   @see Role#name
    delegate :name, to: :role

    def initialize(data, bot)
      @bot = bot

      @guild = bot.guild(data[:guild_id].to_i)
      return unless @guild

      role_id = data[:role][:id].to_i
      @role = @guild.roles.find { |r| r.id == role_id }
    end
  end

  # Event handler for GuildRoleCreateEvent
  class GuildRoleCreateEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? GuildRoleCreateEvent

      [
        matches_all(@attributes[:name], event.name) do |a, e|
          a == if a.is_a? String
                 e.to_s
               else
                 e
               end
        end
      ].reduce(true, &:&)
    end
  end

  # Raised when a role is deleted from a guild
  class GuildRoleDeleteEvent < Event
    # @return [Integer] the ID of the role that got deleted.
    attr_reader :id

    # @return [Guild] the guild on which a role got deleted.
    attr_reader :guild

    def initialize(data, bot)
      @bot = bot

      # The role should already be deleted from the guild's list
      # by the time we create this event, so we'll create a temporary
      # role object for event consumers to use.
      @id = data[:role_id].to_i
      guild_id = data[:guild_id].to_i
      @guild = bot.guild(guild_id)
    end
  end

  # EventHandler for GuildRoleDeleteEvent
  class GuildRoleDeleteEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? GuildRoleDeleteEvent

      [
        matches_all(@attributes[:id], event.id) do |a, e|
          a.resolve_id == e.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Event raised when a role updates on a guild
  class GuildRoleUpdateEvent < GuildRoleCreateEvent; end

  # Event handler for GuildRoleUpdateEvent
  class GuildRoleUpdateEventHandler < GuildRoleCreateEventHandler; end
end
