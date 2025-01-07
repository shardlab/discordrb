# frozen_string_literal: true

module Discordrb
  # A Discord poll attatched to a message.
  class Poll
    # @return [String] Question of the poll.
    attr_reader :question

    # @return [Array<Answer>] Selectable poll answers.
    attr_reader :answers

    # @return [Time] How long this poll will last before expiring.
    attr_reader :expiry
    alias_method :duration, :expiry

    # @return [Boolean] Whether you can select multiple poll answers.
    attr_reader :allow_multiselect
    alias_method :allow_multiselect?, :allow_multiselect
    alias_method :multiselect?, :allow_multiselect

    # @return [Integer] The layout type of this poll.
    attr_reader :layout_type

    # @return [Boolean] Whether the poll results have been precisely counted.
    attr_reader :finalized
    alias_method :finalized?, :finalized

    # @return [Hash<Integer => Integer>] The answer counts by ID.
    attr_reader :answer_counts

    # @return [Message] The message this poll originates from.
    attr_reader :message

    # @!visibility private
    def initialize(data, message, bot)
      @bot = bot
      @message = message
      @question = data['question']['text']
      @answers = data['answers'].map { |answer| Answer.new(answer, @bot, self) }
      @expiry = Time.iso8601(data['expiry']) if data['expiry']
      @allow_multiselect = data['allow_multiselect']
      @layout_type = data['layout_type']
      @finalized = data['results']['is_finalized'] if data['results']
      @answer_counts = process_votes(data['results']['answer_counts']) if data.dig('results', 'answer_counts')
    end

    # Ends this poll. Only works if the bot made the poll.
    # @return [Message] The new message object.
    def end
      response = JSON.parse(API::Channel.end_poll(@bot.token, @message.channel.id, @message.id))
      Message.new(response, @bot)
    end

    # Get a specific answer by its ID.
    # @param id [Integer, String] ID of the answer.
    # @return [Answer, nil]
    def answer(id)
      @answers.find { |a| a.id == id.resolve_id }
    end

    # Whether or not this poll has ended.
    # @return [Boolean]
    def expired?
      return false if @expiry.nil?

      Time.now >= @expiry
    end

    alias_method :ended?, :expired?

    # Returns the answer with the most votes.
    # @return [Answer] The answer object.
    def most_voted
      return nil if @answer_counts.nil?

      answer(@answer_counts.invert.max&.last)
    end

    # Whether this poll is currently tied.
    # @return [Boolean] True if this poll is tied. False otherwise.
    def tied?
      return nil if @answer_counts.nil?

      @answer_counts.values != @answer_counts.values.uniq
    end

    private

    # @!visibility private
    # @note For internal use only
    # Proccess the answer counts hash.
    # @return [Hash] The new answer hash.
    def process_votes(data)
      return nil if data.empty?

      data.each_with_object({}) do |vote, hash|
        hash[vote['id']] = vote['count']
      end
    end

    # Represents a single answer for a poll.
    class Answer
      include IDObject

      # @return [Poll] Poll this answers originates from.
      attr_reader :poll

      # @return [String] Name of this question.
      attr_reader :name

      # @return [Emoji, nil] Emoji associated with this question.
      attr_reader :emoji

      # @!visibility private
      def initialize(data, bot, poll)
        @bot = bot
        @poll = poll
        @name = data['poll_media']['text']
        @id = data['answer_id']
        @emoji = Emoji.new(data['poll_media']['emoji'], @bot) if data.dig('poll_media', 'emoji')
      end

      # Returns how many users have voted for this answer.
      # @return [Integer, nil] Returns the number of votes or nil if they don't exist.
      def votes
        return 0 if !@Poll.answer_counts&.key?(@id) && @poll.finalized?

        @poll.answer_counts&.key(@id)
      end

      # Gets an array of user objects that have voted for this poll.
      # @param after [Integer, String] Gets the users after this user ID.
      # @param limit [Integer] The max number of users between 1-100. Nil will return all users.
      def voters(after: nil, limit: 100)
        get_voters = proc do |fetch_limit, after_id = nil|
          response = JSON.parse(API::Channel.get_answer_voters(@bot.token, @poll.message.channel.id, @poll.message.id, @id, after_id, fetch_limit))
          response['users'].map { |user| User.new(user, @bot) }
        end
  
        return get_voters.call(limit, after) if limit && limit <= 100
  
        paginator = Paginator.new(limit, :down) do |last_page|
          if last_page && last_page.count < 100
            []
          else
            get_voters.call(100, last_page&.last&.id)
          end
        end
  
        paginator.to_a
      end
    end

    # Allows for easy creation of a poll request object.
    class Builder
      # @!attribute question
      # @return [String] Sets the poll question.
      attr_writer :question

      # @!attribute allow_multiselect
      # @return [Boolean] Whether multiple answers can be chosen.
      attr_writer :allow_multiselect
      alias_method :multiselect=, :allow_multiselect=

      # @!attribute layout_type
      # @return [Integer] This can currently only be 1.
      attr_writer :layout_type

      # @!attribute duration
      # @return [Integer] How long this poll should last.
      attr_writer :duration
      alias_method :expiry=, :duration=

      # @param question [String]
      # @param answers [Array<Hash>]
      # @param allow_multiselect [Boolean] Defaults to false.
      # @param duration [Integer] Defaults to 24 hours.
      # @param layout_type [Integer] Defaults to 1.
      def initialize(question: nil, answers: [], allow_multiselect: false, duration: 24, layout_type: 1)
        @question = question
        @answers = answers
        @allow_multiselect = allow_multiselect
        @duration = duration
        @layout_type = layout_type
      end

      # Adds an answer to this poll.
      # @param name [String] Name of the answer.
      # @param emoji [String, Integer, Emoji] An emoji for this poll answer.
      def add_answer(name:, emoji: nil)
        emoji = case emoji
                when Integer, String
                  emoji.to_i.positive? ? { id: emoji } : { name: emoji }
                when Reaction, Emoji
                  emoji.id ? { id: emoji.id } : { name: emoji.name }
                end

        @answers << { poll_media: { text: name, emoji: emoji }.compact }
      end

      alias_method :add_option, :add_answer
      alias_method :add_choice, :add_answer

      # @!visibility private
      # Converts the poll into a hash that can be sent to Discord.
      def to_hash
        {
          question: { text: @question },
          answers: @answers,
          allow_multiselect: @allow_multiselect,
          duration: @duration,
          layout_type: @layout_type
        }.to_h
      end
    end
  end
end
