# frozen_string_literal: true

require 'discordrb/events/generic'
require 'discordrb/data'

module Discordrb::Events
  # Generic subclass for guild member events (add/update/delete)
  class GuildMemberEvent < Event
    # @return [Member] the member in question.
    attr_reader :user
    alias_method :member, :user

    # @return [Array<Role>] the member's roles.
    attr_reader :roles

    # @return [Guild] the guild on which the event happened.
    attr_reader :guild

    def initialize(data, bot)
      @bot = bot

      @guild = bot.guild(data[:guild_id].to_i)
      return unless @guild

      init_user(data, bot)
      init_roles(data, bot)
    end

    private

    def init_user(data, _)
      user_id = data[:user][:id].to_i
      @user = @guild.member(user_id)
    end

    def init_roles(data, _)
      @roles = [@guild.role(@guild.id)]
      return unless data[:roles]

      data[:roles].each do |element|
        role_id = element.to_i
        @roles << @guild.roles.find { |r| r.id == role_id }
      end
    end
  end

  # Generic event handler for member events
  class GuildMemberEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type
      return false unless event.is_a? GuildMemberEvent

      [
        matches_all(@attributes[:username], event.user.name) do |a, e|
          a == if a.is_a? String
                 e.to_s
               else
                 e
               end
        end
      ].reduce(true, &:&)
    end
  end

  # Member joins
  # @see Discordrb::EventContainer#member_join
  class GuildMemberAddEvent < GuildMemberEvent; end

  # Event handler for {GuildMemberAddEvent}
  class GuildMemberAddEventHandler < GuildMemberEventHandler; end

  # Member is updated (roles added or deleted)
  # @see Discordrb::EventContainer#member_update
  class GuildMemberUpdateEvent < GuildMemberEvent; end

  # Event handler for {GuildMemberUpdateEvent}
  class GuildMemberUpdateEventHandler < GuildMemberEventHandler; end

  # Member leaves
  # @see Discordrb::EventContainer#member_leave
  class GuildMemberDeleteEvent < GuildMemberEvent
    # Override init_user to account for the deleted user on the guild
    def init_user(data, bot)
      @user = Discordrb::User.new(data[:user], bot)
    end

    # @return [User] the user in question.
    attr_reader :user
  end

  # Event handler for {GuildMemberDeleteEvent}
  class GuildMemberDeleteEventHandler < GuildMemberEventHandler; end
end
