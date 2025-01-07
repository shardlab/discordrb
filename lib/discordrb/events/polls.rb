# frozen_string_literal: true

require 'discordrb/data'
require 'discordrb/events/generic'

module Discordrb::Events
  # Raised when a user votes for a poll option.
  class PollVoteAddEvent < Event
    # @return [User, Member, nil] The user that added or removed a vote.
    attr_reader :user
    alias_method :member, :user

    # @return [Server, nil] The server where this poll originates from.
    attr_reader :server

    # @return [Channel] The channel where this poll originates from.
    attr_reader :channel

    # @return [Message] The message where this poll originates from.
    attr_reader :message

    # @return [Poll::Answer] The answer that got voted for or had their vote removed.
    attr_reader :answer

    # @return [Poll] The poll that triggered this event.
    attr_reader :poll

    def initialize(data, bot)
      @bot = bot

      @server = bot.server(data['guild_id']) if data['guild_id']
      @channel = bot.channel(data['channel_id'])
      @message = @channel.load_message(data['message_id'])
      @poll = @message.poll
      @answer = @poll.answer(data['answer_id'])
      @user = data['guild_id'] ? bot.member(data['guild_id'], data['user_id']) : bot.user(data['user_id'])
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
