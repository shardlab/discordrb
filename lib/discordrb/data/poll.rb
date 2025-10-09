# frozen_string_literal: true

module Discordrb
  # A surface with selectable answers that can be voted for.
  class Poll
    # @return [String] the question of this poll.
    attr_reader :question

    # @return [Array<Answer>] the selectable answers of this poll.
    attr_reader :answers

    # @return [Time, nil] the time at when this poll will close.
    attr_reader :ends_at

    # @return [true, false] whether multiple poll answers can be selected.
    attr_reader :multiselect
    alias_method :multiselect?, :multiselect

    # @return [Integer] the layout type of this poll. Currently always `1`.
    attr_reader :layout_type

    # @return [true, false] whether this poll has closed and the results have
    #   been precisely counted by Discord's backend.
    attr_reader :finished
    alias_method :finished?, :finished

    # @!visibility private
    def initialize(data, message, bot)
      @bot = bot
      @message = message
      @layout_type = data['layout_type']
      @question = data['question']['text']
      @multiselect = data['allow_multiselect']
      @ends_at = data['expiry'] ? Time.parse(data['expiry']) : nil
      @finished = data['results'] ? data['results']['is_finalized'] : false
      @results = data['results'] ? data['results']['answer_counts']&.to_h { |opt| [opt['id'], opt['count']] } : {}
      @answers = data['answers'].map { |answer| Answer.new(answer.merge({ 'results' => @results }), message, bot) }
    end

    # Get the total amount of users that voted on this poll.
    # @return [Integer] the total amount of votes cast on this poll.
    def total_votes
      @results.values.sum
    end

    # Whether this poll has ended.
    # @return [true, false] whether or not this poll has ended.
    def ended?
      !@ends_at.nil? && @ends_at < Time.now
    end

    # Get a specific answer from this poll by its ID.
    # @param id [Integer, String] the ID of the answer to find.
    # @return [Answer, nil] the answer of this poll, or `nil` if it can't be found.
    def answer(id)
      @answers.find { |answer| answer.id == id.to_i }
    end

    # Get the answer that has the most amount of votes.
    # @return [Answer, nil] the answer with the most votes, or `nil` if the results are tied.
    def winner
      @answers.max_by(&:votes) unless tied?
    end

    # Whether the results of this poll are tied.
    # @return [true, false] whether or not there are poll answers with the same amount of votes.
    def tied?
      return true if @results.values.sum.zero?

      @results.values.reject(&:zero?).tally.any? { |_, vote| vote > 1 }
    end

    # Get the original duration of this poll in hours.
    # @return [Integer, nil] the duration of this poll, or `nil` if it doesn't have a duration.
    def original_duration
      ((@ends_at - @message.creation_time) / 3600).round(0) if @ends_at
    end

    # Immediately ends this poll. This can only be done if the author of the poll is the current bot.
    # @return [Message] the updated message object with the newly ended poll.
    def end
      raise 'The bot cannot end a poll that was sent by a different user.' unless @message.from_bot?

      Message.new(JSON.parse(API::Channel.end_poll(@bot.token, @message.channel.id, @message.id)), @bot)
    end

    # @!visibility private
    def to_h
      {
        question: { text: @question },
        answers: @answers.map(&:to_h),
        allow_multiselect: @multiselect,
        layout_type: @layout_type,
        duration: original_duration
      }
    end

    # A selectable poll answer that can be voted for.
    class Answer
      # @return [Integer] the ID of this poll answer.
      attr_reader :id

      # @return [String, nil] the text of this poll answer.
      attr_reader :name

      # @return [Integer] the voter count of this poll answer.
      attr_reader :votes

      # @return [Emoji, nil] the custom emoji of this poll answer.
      attr_reader :emoji

      # @!visibility private
      def initialize(data, message, bot)
        @bot = bot
        @message = message
        @id = data['answer_id']
        @name = data['poll_media']['text']
        @votes = data['results'][@id] || 0
        @emoji = Emoji.new(data['poll_media']['emoji'], bot) if data['poll_media']['emoji']
      end

      # Get the users that have voted for this poll answer.
      # @param limit [Integer, nil] The maximum number of users to get. `nil` will returns all users.
      # @return [Array<User>] the users that voted for this poll answer.
      def voters(limit: 100)
        get_voters = proc do |fetch_limit, after = nil|
          response = API::Channel.get_poll_answer_voters(@bot.token, @message.channel.id, @message.id, @id, limit: fetch_limit, after: after)
          JSON.parse(response)['users'].map { |user_data| User.new(user_data, @bot) }
        end

        # Can be done without pagination.
        return get_voters.call(limit) if limit && limit <= 100

        paginator = Paginator.new(limit, :down) do |last_page|
          if last_page && last_page.count < 100
            []
          else
            get_voters.call(100, last_page&.last&.id)
          end
        end

        paginator.to_a
      end

      # Await a poll vote, blocking.
      # @param attributes [Hash] The event's attributes.
      # @option attributes [String, Integer, User, Member] :user A user to match against.
      # @yield The block is executed when the event is raised.
      # @yieldparam event [PollVoteAddEvent] The event that was raised.
      def await_vote!(**attributes, &block)
        @bot.add_await!(Discordrb::Events::PollVoteAddEvent, { answer: @id, message: @message.id }.merge(attributes), &block)
      end

      # @!visibility private
      def to_h
        { poll_media: { text: @name, emoji: @emoji&.to_h }.compact }
      end

      # @!visibility private
      def inspect
        "<Answer id=#{@id} name=#{@name} votes=#{@votes} emoji=#{@emoji&.inspect || 'nil'}>"
      end
    end

    # Builder for creating a poll request object.
    class Builder
      # @!attribute question
      # @return [String] the poll's question.
      attr_writer :question

      # @!attribute multiselect
      # @return [true, false] whether multiple answers can be chosen.
      attr_writer :multiselect

      # @!attribute layout_type
      # @return [Integer] the poll's layout type. This can currently only be 1.
      attr_writer :layout_type

      # @!visibility private
      def initialize
        @answers = []
        @duration = 24
        @question = nil
        @layout_type = 1
        @multiselect = false
      end

      # Set the duration of the poll.
      # @param duration [Time, Integer] the duration of the poll in hours,
      #   or the time at when the poll should expire. A poll's maximum duration is 768 hours.
      def duration=(duration)
        @duration = duration.is_a?(Time) ? ((duration - Time.now) / 3600).round(0) : duration
      end

      alias_method :ends_at=, :duration=

      # Add an answer to the poll.
      # @param name [String] the name of the answer.
      # @param emoji [String, Integer, Emoji, nil] an optional emoji for the answer.
      def answer(name:, emoji: nil)
        emoji = case emoji
                when Integer, String
                  emoji.to_i.positive? ? { id: emoji } : { name: emoji }
                when Reaction, Emoji
                  emoji.id.nil? ? { name: emoji.name } : { id: emoji.id }
                end

        @answers << { poll_media: { text: name, emoji: emoji }.compact }
      end

      alias_method :add_answer, :answer

      # @!visibility private
      def to_h
        {
          question: { text: @question },
          answers: @answers,
          allow_multiselect: @multiselect,
          layout_type: @layout_type,
          duration: @duration&.clamp(1, 768)
        }
      end
    end
  end
end
