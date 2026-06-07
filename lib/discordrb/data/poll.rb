# frozen_string_literal: true

module Discordrb
  # A surface with selectable answers.
  class Poll
    # Mapping of layout types for polls.
    LAYOUTS = {
      default: 1
    }.freeze

    # @return [Integer] the layout type of the poll.
    attr_reader :layout

    # @return [Array<Answer>] the answers of the poll.
    attr_reader :answers

    # @return [Message] the message linked to the poll.
    attr_reader :message

    # @return [Media] the display-data for the poll question.
    attr_reader :question

    # @return [Time, nil] the time at when the poll will expire.
    attr_reader :closes_at

    # @return [true, false] whether or not Discord has precisely counted the votes yet.
    attr_reader :finalised
    alias finalised? finalised
    alias finalized? finalised

    # @return [true, false] whether or not users are allowed to vote for multiple answers.
    attr_reader :multiselect
    alias multiselect? multiselect

    # @return [true, false] whether or not Discord did not fetch the results for the poll.
    #   When this is `true`, the {#finalised?} method will always return a value of `false`,
    #   and {Answer#votes} will always return a value of `0`.
    attr_reader :unknown_results
    alias unknown_results? unknown_results

    # @!visibility private
    def initialize(data, message, bot)
      @bot = bot
      @message = message
      @layout = data['layout_type']
      @question = Media.new(data['question'], @bot)
      @multiselect = data['allow_multiselect']
      @closes_at = Time.parse(data['expiry']) if data['expiry']
      results = data['results']
      @unknown_results = results.nil?
      @finalised = results&.[]('is_finalized') || false
      process_answers(data['answers'], results&.[]('answer_counts'))
    end

    # Get the total amount of votes cast on the poll.
    # @return [Integer] The total amount of votes that the poll received.
    def total_votes
      @answers.sum(&:votes)
    end

    # Get a single answer for the poll by its ID.
    # @param answer_id [Integer, String, Answer] The ID of the poll answer.
    # @return [Answer, nil] The poll answer, or `nil` if it couldn't be found.
    def answer(answer_id)
      answer_id = if answer_id.is_a?(Answer)
                    answer_id.id
                  else
                    answer_id.resolve_id
                  end

      @answers.find { |answer| answer.id == answer_id }
    end

    # Check if the poll has closed.
    # @return [true, false] Whether or not the poll has closed.
    def closed?
      @finalised || (!@closes_at.nil? && Time.now > @closes_at)
    end

    # Get the poll answer that has the most amount of votes.
    # @return [Answer, nil] The winning poll answer, or `nil` for no winner.
    def winner
      return unless (max = @answers.max_by(&:votes))&.votes&.nonzero?

      @answers.one? { |answer| answer.votes == max&.votes } ? max : nil
    end

    # Prematurely end the poll, only functional for polls created by the current bot.
    # @return [Message] The resulting message. Will fail if the poll was not sent by the current bot.
    # @raise [Discordrb::Errors::NoPermission] If the poll was not created by the current bot account.
    def close
      raise Discordrb::Errors::NoPermission, 'Cannot close the poll' if !@message.from_bot? || closed?

      Message.new(JSON.parse(API::Channel.end_poll(@bot.token, @message.channel.id, @message.id)), @bot)
    end

    # Check if two poll objects are equivalent.
    # @param other [Object] The object to compare the poll object against.
    # @return [true, false] Whether or not the poll objects are equivalent.
    def ==(other)
      other.is_a?(Poll) ? @message == other.message : false
    end

    alias_method :eql?, :==

    # @!method default_layout?
    #   @return [true, false] whether or not the poll is using the default layout.
    LAYOUTS.each do |name, value|
      define_method("#{name}_layout?") { @layout == value }
    end

    # @!visibility private
    def inspect
      "<Poll question=\"#{@question.text}\" unknown_results=#{@unknown_results}>"
    end

    # @!visibility private
    def to_h
      {
        layout_type: @layout,
        question: @question.to_h,
        answers: @answers.map(&:to_h),
        allow_multiselect: @multiselect,
        duration: @closes_at ? ((@closes_at - @message.creation_time) / 3600).round : nil
      }
    end

    private

    # @!visibility private
    def process_answers(answers, counts)
      @answers = answers.map do |answer|
        count_data = counts&.find { |count| count['id'] == answer['answer_id'] }

        Answer.new(answer.tap { answer['_votes'] = count_data&.[]('count') }, self, @bot)
      end
    end

    # A selectable poll answer.
    class Answer
      # @return [Integer] the ID of the poll answer.
      attr_reader :id

      # @return [Integer] the number of votes the answer has.
      attr_reader :votes
      alias vote_count votes

      # @return [Integer] the ID of the message the answer is from.
      attr_reader :message_id

      # @!visibility private
      def initialize(data, poll, bot)
        @bot = bot
        @poll = poll
        @id = data['answer_id']
        @votes = data['_votes'] || 0
        @media = Media.new(data['poll_media'], @bot)
        @channel_id = data['_channel_id'] unless @poll
        @message_id = @poll&.message&.id || data['_message_id']&.to_i
      end

      # Get the text of the poll answer.
      # @return [String] The text of the poll answer.
      def text
        @media.text
      end

      # Get the emoji of the poll answer.
      # @return [Emoji, nil] The emoji of the poll answer.
      def emoji
        @media.emoji
      end

      # Check if the poll answer won the poll.
      # @return [true, false] Whether or not the poll answer is the winner.
      def winner?
        @poll.nil? || @poll.winner&.id == @id
      end

      # Get the users who voted for the poll answer.
      # @param after [Time, #resolve_id, nil] The ID or timestamp to start fetching voters from.
      # @param limit [Integer, nil] The maximum number of voters to fetch, or `nil` to fetch all the voters.
      # @return [Array<User>] The users who voted for the poll answer; ordered by user ID in ascending order.
      def voters(after: nil, limit: 100)
        stable = @poll.nil? || @poll.finalised?
        channel_id = @channel_id || @poll.message.channel.id
        after_time = after.is_a?(Time) ? IDObject.synthesise(after) : after&.resolve_id

        get_users = lambda do |limit, after|
          data = API::Channel.get_poll_voters(@bot.token, channel_id, @message_id, @id, after:, limit:)
          JSON.parse(data)['users'].collect { |poll_voter_data| @bot.ensure_user(poll_voter_data) }
        end

        return get_users.call(limit, after_time) if limit && limit <= 100

        paginator = Paginator.new(limit, :down) do |last_page|
          if stable && last_page && last_page.count < 100
            []
          else
            get_users.call(100, last_page&.last&.id || after_time)
          end
        end

        paginator.to_a
      end

      # Check if two poll answers are equivalent.
      # @param other [Object] The object to compare the poll answer against.
      # @return [true, false] Whether or not the poll answers are equivalent.
      def ==(other)
        return false unless other.is_a?(Answer)

        @message_id == other.message_id && @id == other.id
      end

      alias_method :eql?, :==

      # @!visibility private
      def to_h
        { poll_media: @media.to_h }
      end

      # @!visibility private
      def inspect
        "<Answer id=#{@id} text=\"#{text}\" votes=#{@votes}>"
      end
    end

    # Represents display-data for a poll.
    class Media
      # @return [String, nil] the text of the poll media.
      attr_reader :text

      # @return [Emoji, nil] the emoji of the poll media.
      attr_reader :emoji

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @text = data['text']
        @emoji = Emoji.new(data['emoji'], @bot) if data['emoji']
      end

      # Check if two poll media objects are equivalent.
      # @param other [Object] The object to compare the poll media against.
      # @return [true, false] Whether or not the poll media objects are equivalent.
      def ==(other)
        return false unless other.is_a?(Media)

        @text == other.text && @emoji == other.emoji
      end

      alias_method :eql?, :==

      # @!visibility private
      def to_h
        { text: @text, emoji: @emoji&.to_h }.compact
      end

      # @!visibility private
      def inspect
        "<Media text=\"#{@text}\" emoji=#{@emoji.inspect}>"
      end
    end

    # Finalised results for a poll.
    class Result
      # @return [Answer, nil] the answer that won the poll, if any.
      attr_reader :winner
      alias answer winner

      # @return [Media] the display-data for the question of the poll.
      attr_reader :question

      # @return [Integer] the ID of the message the poll result is for.
      attr_reader :message_id

      # @return [Integer] the total amount of votes that the poll received.
      attr_reader :total_votes

      # @!visibility private
      def initialize(embed, reference, bot)
        @bot = bot
        @message_id = reference['message_id'].to_i
        embed = embed['fields'].to_h { |field| [field['name'], field['value']] }
        @question = Media.new({ 'text' => embed['poll_question_text'] }, @bot)
        @total_votes = embed['total_votes'].to_i
        return unless (id = embed['victor_answer_id']&.to_i)

        data = {
          'poll_media' => {
            'text' => embed['victor_answer_text']
          },
          'answer_id' => id,
          '_message_id' => @message_id,
          '_channel_id' => reference['channel_id'],
          '_votes' => embed['victor_answer_votes'].to_i
        }

        if embed['victor_answer_emoji_id'] || embed['victor_answer_emoji_name']
          data['poll_media']['emoji'] = {
            'name' => embed['victor_answer_emoji_name'],
            'id' => embed['victor_answer_emoji_id']&.to_i,
            'animated' => embed['victor_answer_emoji_animated'] == 'true'
          }
        end

        @winner = Answer.new(data, nil, @bot)
      end

      # Check if two result objects are equivalent.
      # @param other [Object] The object to compare the result object against.
      # @return [true, false] Whether or not the result objects are equivalent.
      def ==(other)
        other.is_a?(Result) ? @message_id == other.message_id : false
      end

      alias_method :eql?, :==

      # @!visibility private
      def inspect
        "<Result winner=#{@winner.inspect} total_votes=#{@total_votes}>"
      end
    end

    # Builder for polls.
    class Builder
      # Create a poll request object.
      # @param question [String] The question of the poll; between 1-55 characters.
      # @param layout [Integer, Symbol, nil] The layout type of the poll; see {LAYOUTS}.
      # @param duration [Integer, Time, nil] The number of hours before the poll expires.
      # @param multiselect [true, false, nil] Whether or not users can pick multiple answers.
      def initialize(question:, layout: :default, duration: 24, multiselect: false)
        @layout = layout
        @answers = []
        @question = question
        @duration = duration || 24
        @multiselect = multiselect
      end

      # Add an answer to the poll builder.
      # @param text [String] The text of the poll answer.
      # @param emoji [Emoji, Reaction, Integer, String, nil] The emoji of the poll answer.
      # @return [void]
      def answer(text:, emoji: nil)
        emoji = Emoji.build_emoji_hash(emoji, prefix: false) if emoji

        @answers << { poll_media: { text: text, emoji: emoji }.compact }
      end

      alias_method :add_answer, :answer

      # @!visibility private
      def to_h
        {
          question: { text: @question },
          answers: @answers,
          layout_type: LAYOUTS[@layout] || @layout,
          allow_multiselect: @multiselect,
          duration: @duration.is_a?(Time) ? ((@duration - Time.now) / 3600).round : @duration
        }
      end
    end
  end
end
