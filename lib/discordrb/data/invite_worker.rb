# frozen_string_literal: true

module Discordrb
  # The worker for an invite's target users.
  class TargetUsersWorker
    # Map of status types.
    STATUSES = {
      unspecified: 0,
      processing: 1,
      completed: 2,
      failed: 3
    }.freeze

    # @return [Integer] the status of the worker.
    attr_reader :status

    # @return [Integer] the total amount of users the worker must process.
    attr_reader :total_count

    # @return [String, nil] the error message if the worker didn't finish.
    attr_reader :error_message

    # @return [Time] the time at when the asynchronous worker was created.
    attr_reader :creation_time

    # @return [Integer] the number of users the worker has processed so far.
    attr_reader :completed_count

    # @return [Time, nil] the time at when the worker finished processing all the users.
    attr_reader :completion_time

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @status = data['status']
      @total_count = data['total_users']
      @error_message = data['error_message']
      @completed_count = data['processed_users']
      @creation_time = Time.parse(data['created_at'])
      @completion_time = Time.parse(data['completed_at']) if data['completed_at']
    end

    # @!method unspecified?
    #   @return [true, false] whether or not the worker is idle.
    # @!method processing?
    #   @return [true, false] whether or not the worker is processing the users.
    # @!method completed?
    #   @return [true, false] whether or not the worker is done processing the users.
    # @!method failed?
    #   @return [true, false] whether or not the worker failed to process any of the users.
    STATUSES.each do |name, value|
      define_method("#{name}?") do
        @status == value
      end
    end
  end
end
