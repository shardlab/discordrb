# frozen_string_literal: true

require 'discordrb/data'
require 'discordrb/events/generic'

module Discordrb::Events
  # Generic superclass for poll events.
  class PollVoteEvent < Event
    # @return [Integer] the ID of the user associated with the event.
    attr_reader :user_id

    # @return [Integer, nil] the ID of the server associated with the
    #   event.
    attr_reader :server_id

    # @return [Integer] the ID of the answer associated with the event.
    attr_reader :answer_id

    # @return [Integer] the ID of the channel associated with the event.
    attr_reader :channel_id

    # @return [Integer] the ID of the message associated with the event.
    attr_reader :message_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @user_id = data['user_id']&.to_i
      @server_id = data['guild_id']&.to_i
      @answer_id = data['answer_id']&.to_i
      @channel_id = data['channel_id']&.to_i
      @message_id = data['message_id']&.to_i
    end

    # Get the poll associated with the event.
    # @return [Poll] The poll associated with the event.
    def poll
      message&.poll
    end

    # Get the poll answer associated with the event.
    # @return [Poll::Answer] The poll answer associated with the event.
    def answer
      poll&.answer(@answer_id)
    end

    # Get the channel that the poll originates from.
    # @return [Channel] The channel that the poll originates from.
    def channel
      @bot.channel(@channel_id)
    end

    # Get the server that the poll originates from.
    # @return [Server, nil] The server that the poll originates from.
    def server
      @bot.server(@server_id) if @server_id
    end

    # Get the message that the poll originates from.
    # @return [Message] The message that the poll originates from.
    def message
      @message ||= channel.load_message(@message_id)
    end

    # Get the user who added or removed their poll vote.
    # @return [User, Member] The member who added the poll vote, or
    #   a user if the member cannot be reached, or the poll was created
    #   in a DM channel.
    def user
      @user ||= (server&.member(@user_id) || @bot.user(@user_id))
    end

    alias_method :member, :user
  end

  # Generic event handler for polls.
  class PollVoteEventHandler < EventHandler
    # @!visibility private
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(PollVoteEvent)

      [
        matches_all(@attributes[:answer], event.answer_id) do |a, e|
          (a.respond_to?(:id) ? a.id : a&.resolve_id) == e
        end,

        matches_all(@attributes[:server], event.server_id) do |a, e|
          a&.resolve_id == e
        end,

        matches_all(@attributes[:message], event.message_id) do |a, e|
          a&.resolve_id == e
        end,

        matches_all(@attributes[:channel], event.channel_id) do |a, e|
          a&.resolve_id == e
        end,

        matches_all(@attributes[:user] || @attributes[:member], event.user_id) do |a, e|
          a&.resolve_id == e
        end
      ].reduce(true, &:&)
    end
  end

  # Raised whenever someone votes on a poll.
  class PollVoteAddEvent < PollVoteEvent; end

  # Raised whenever someone removes a poll vote.
  class PollVoteRemoveEvent < PollVoteEvent; end

  # Event handler for the :MESSAGE_POLL_VOTE_ADD event.
  class PollVoteAddEventHandler < PollVoteEventHandler; end

  # Event handler for the :MESSAGE_POLL_VOTE_REMOVE event.
  class PollVoteRemoveEventHandler < PollVoteEventHandler; end
end
