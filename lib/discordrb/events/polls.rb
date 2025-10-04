# frozen_string_literal: true

module Discordrb::Events
  # Generic superclass for poll events.
  class PollVoteEvent < Event
    # @!visibility private
    attr_reader :user_id

    # @!visibility private
    attr_reader :server_id

    # @!visibility private
    attr_reader :answer_id

    # @!visibility private
    attr_reader :channel_id

    # @!visibility private
    attr_reader :message_id

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @user_id = data['user_id'].to_i
      @server_id = data['guild_id']&.to_i
      @answer_id = data['answer_id'].to_i
      @channel_id = data['channel_id'].to_i
      @message_id = data['message_id'].to_i
    end

    # The poll that was actioned on.
    # @return [Poll] the poll in question.
    def poll
      message.poll
    end

    # The poll answer that was actioned on.
    # @return [Poll::Answer] the answer that was actioned on.
    def answer
      poll.answer(@answer_id)
    end

    # The channel where the poll was actioned on.
    # @return [Channel] the channel the poll message is from.
    def channel
      @bot.channel(@channel_id)
    end

    # The server where the poll was actioned on.
    # @return [Server, nil] the server the poll message is from.
    def server
      @bot.server(@server_id) if @server_id
    end

    # The message the poll that was actioned on is attached to.
    # @return [Message] the message the poll is from.
    def message
      @message ||= channel.load_message(@message_id)
    end

    # The user who added or removed their poll vote.
    # @return [User, Member] This will be a member if the poll was
    #   created in a server. This will be a user if this member has since
    #   left the server or the poll was created in a direct message with the bot.
    def user
      return @bot.user(@user_id) if @server_id.nil?

      server.member(@user_id) || @bot.user(@user_id)
    end

    alias_method :member, :user
  end

  # Generic superclass for event handlers pertaining to poll votes.
  class PollVoteEventHandler < EventHandler
    def matches?(event)
      # Check for the proper event type.
      return false unless event.is_a?(PollVoteEvent)

      [
        matches_all(@attributes[:user], event.user_id) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:server], event.server_id) do |a, e|
          a.resolve_id == e&.resolve_id
        end,

        matches_all(@attributes[:message], event.message_id) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:channel], event.channel_id) do |a, e|
          a.resolve_id == e.resolve_id
        end,

        matches_all(@attributes[:answer], event.answer_id) do |a, e|
          (a.respond_to?(:id) ? a.id : a&.to_i) == e.resolve_id
        end
      ].reduce(true, &:&)
    end
  end

  # Raised whenever someone votes on a poll.
  class PollVoteAddEvent < PollVoteEvent; end

  # Raised whenever someone removes a poll vote.
  class PollVoteRemoveEvent < PollVoteEvent; end

  # Event handler for the PollVoteAddEvent.
  class PollVoteAddEventHandler < PollVoteEventHandler; end

  # Event handler for the PollVoteRemoveEvent.
  class PollVoteRemoveEventHandler < PollVoteEventHandler; end
end
