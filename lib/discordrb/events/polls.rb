# frozen_string_literal: true

require 'discordrb/data'
require 'discordrb/events/generic'

module Discordrb::Events
  # Raised when a user votes for a poll option.
  class PollVoteAddEvent < Event
    # @!visibility private
    attr_reader :server_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot

      @user_id = data['user_id'].to_i
      @server_id = data['guild_id']&.to_i
      @answer_id = data['answer_id'].to_i
      @message_id = data['message_id'].to_i
      @channel_id = data['channel_id'].to_i
    end

    # @return [User, Member] the user that reacted to this message, or member if a server exists.
    def user
      @user ||= server ? @server.member(@user_id) : @bot.user(@user_id)
    end

    alias_method :member, :user

    # @return [Poll] The poll that triggered this event.
    def poll
      @poll ||= message.poll
    end

    # @return [Message] The message where this poll originates from.
    def message
      @message ||= channel.load_message(@message_id)
    end

    # @return [Poll::Answer] The answer that got voted for or had their vote removed.
    def answer
      @answer ||= poll.answer(@answer_id)
    end

    # @return [Channel] The channel where this poll originates from.
    def channel
      @channel ||= @bot.channel(@channel_id)
    end

    # @return [Server, nil] The server where this poll originates from.
    def server
      @server ||= channel.server
    end
  end

  # Event handler for PollVoteAddEvent.
  class PollVoteAddEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a? PollVoteAddEvent

      [
        matches_all(@attributes[:user], event.user) { |a, e| a.resolve_id == e.id },
        matches_all(@attributes[:server], event.server) { |a, e| a.resolve_id == e&.id },
        matches_all(@attributes[:channel], event.channel) { |a, e| a.resolve_id == e.id },
        matches_all(@attributes[:message], event.message) { |a, e| a.resolve_id == e.id },
        matches_all(@attributes[:answer_id], event.answer) { |a, e| a.resolve_id == e.id }
      ].reduce(true, &:&)
    end
  end

  # Raised when a user removes a vote from a poll answer.
  class PollVoteRemoveEvent < PollVoteAddEvent; end

  # Event handler for a poll vote remove event.
  class PollVoteRemoveEventHandler < PollVoteAddEventHandler; end
end
