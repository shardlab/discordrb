# frozen_string_literal: true

module Discordrb
  # A call in a private channel.
  class Call
    # @return [Time, nil] the time at when the call ended.
    attr_reader :ended_at

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @participant_ids = data['participants'] || []
      @ended_at = Time.iso8601(data['ended_timestamp']) if data['ended_timestamp']
    end

    # Get the users that participated in this call.
    # @return [Array<User>] the participants of this call.
    def participants
      @participants ||= @participant_ids.map { |participant| @bot.user(participant) }
    end
  end
end
