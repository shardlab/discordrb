# frozen_string_literal: true

module Discordrb
  # A scheduled event for an occurrence on a server.
  class ScheduledEvent
    include IDObject

    # Map of status types.
    STATUSES = {
      scheduled: 1,
      active: 2,
      completed: 3,
      canceled: 4
    }.freeze

    # Map of entity types.
    ENTITY_TYPES = {
      stage: 1,
      voice: 2,
      external: 3
    }.freeze

    # @return [String] the name of the scheduled event.
    attr_reader :name

    # @return [Integer] the current status of the scheduled event.
    attr_reader :status

    # @return [Server] the server associated with the scheduled event.
    attr_reader :server

    # @return [Time, nil] the time at when the scheduled event will end.
    attr_reader :ends_at

    # @return [Time] the time at when the scheduled event will start.
    attr_reader :starts_at

    # @return [String, nil] the external location of the scheduled event.
    attr_reader :location

    # @return [String, nil] the image hash of the scheduled event's cover image.
    attr_reader :cover_id

    # @return [Integer, nil] the ID of an entity associated with the scheduled event.
    attr_reader :entity_id

    # @return [Integer] the type of the entity that is assoicated with the scheduled event.
    attr_reader :entity_type

    # @return [String, nil] the description of the scheduled event. Between 1-1000 characters.
    attr_reader :description

    # @return [RecurrenceRule, nil] the definition for how often this scheduled event should repeat.
    attr_reader :recurrence_rule

    # @!visibility private
    def initialize(data, server, bot)
      @bot = bot
      @server = server
      @id = data['id'].to_i
      @creator_id = data['creator_id']
      @subscriber_count = data['user_count']
      bot.ensure_user(data['creator']) if data['creator']
      from_other(data)
    end

    # Get the user who was responsible for the creation of the scheduled event.
    # @return [User, nil] the user who was responsible for the creation of the scheduled event.
    def creator
      @bot.user(@creator_id) if @creator_id
    end

    # Get the channel in which the scheduled event will be hosted. This can be `nil` if the type is external.
    # @return [Channel, nil] the channel where the scheduled event will take place, or `nil` if there isn't one.
    def channel
      @bot.channel(@channel_id) if @channel_id
    end

    # Utility method to get a scheduled event's cover image URL.
    # @param format [String] the URL will default to `webp`. You can otherwise specify one of `jpg` or `png` to override this.
    # @return [String, nil] the URL to the scheduled event's cover image, or `nil` if the scheduled event doesn't have a cover image.
    def cover_url(format = 'webp')
      API.scheduled_event_cover_url(@id, @cover_id, format) if @cover_id
    end

    # @!method scheduled?
    #   @return [true, false] whether the scheduled event has been scheduled to take place.
    # @!method active?
    #   @return [true, false] whether the scheduled event is currently taking place.
    # @!method completed?
    #   @return [true, false] whether the scheduled event has finished taking place.
    # @!method canceled?
    #   @return [true, false] whether the scheduled event has been canceled.
    STATUSES.each do |name, value|
      define_method("#{name}?") do
        @status == value
      end
    end

    # @!method stage?
    #   @return [true, false] whether the scheduled event will take place in a stage channel.
    # @!method voice?
    #   @return [true, false] whether the scheduled event will take place in a voice channel.
    # @!method external?
    #   @return [true, false] whether the scheduled event will take place in an external location.
    ENTITY_TYPES.each do |name, value|
      define_method("#{name}?") do
        @entity_type == value
      end
    end

    # Set the name of the scheduled event to something new.
    # @param name [String] the new name of the scheduled event.
    def name=(name)
      update_data(name: name)
    end

    # Set the description of the scheduled event to something new.
    # @param description [String, nil] the new description of the scheduled event.
    def description=(description)
      update_data(description: description)
    end

    # Set the recurrence rule of the scheduled event to something new.
    # @param rule [#to_h, nil] the new recurrence rule of the scheduled event.
    def recurrence_rule=(rule)
      update_data(recurrence_rule: rule&.to_h)
    end

    # Set the cover image of the scheduled event to something new.
    # @param cover [File, #read] the new cover image of the scheduled event.
    def cover=(cover)
      update_data(image: Discordrb.encode64(cover))
    end

    # Set the channel where the scheduled event will occur to something new.
    # @param channel [Channel, Integer, String, nil] the new channel of the scheduled event.
    def channel=(channel)
      update_data(channel_id: channel&.resolve_id)
    end

    # Set the external location of the scheduled event to something new.
    # @param location [String, nil] the new location of the scheduled event.
    def location=(location)
      entity_metadata = { location: } if location

      update_data(entity_metadata: entity_metadata)
    end

    # Set the status of the scheduled event to something new.
    # @param status [Symbol, Integer] the new status of the scheduled event.
    def status=(status)
      update_data(status: STATUSES[status] || status)
    end

    # Set the time at when the scheduled event will end to something new.
    # @param end_time [Time] the new end time of the scheduled event.
    def ends_at=(end_time)
      update_data(scheduled_end_time: end_time.iso8601)
    end

    # Set the entity type of the scheduled event to something new.
    # @param type [Symbol, Integer] the new entity type of the scheduled event.
    def entity_type=(type)
      update_data(entity_type: ENTITY_TYPES[type] || type)
    end

    # Set the time at when the scheduled event will start to something new.
    # @param start_time [Time] the new start time of the scheduled event.
    def starts_at=(start_time)
      update_data(scheduled_start_time: start_time.iso8601)
    end

    # Start the scheduled event.
    # @param reason [String, nil] the reason for starting this event.
    # @return [void]
    def start(reason: nil)
      raise 'cannot start this event' unless scheduled?

      update_data(status: STATUSES[:active], reason: reason)
    end

    # Cancel the scheduled event. This cannot be undone.
    # @param reason [String, nil] the reason for cancelling this event.
    # @return [void]
    def cancel(reason: nil)
      raise 'cannot cancel this event' unless scheduled?

      update_data(status: STATUSES[:canceled], reason: reason)
    end

    # End the scheduled event. This cannot be undone.
    # @param reason [String, nil] the reason for ending this event.
    # @return [void]
    def end(reason: nil)
      raise 'cannot end this event' unless active?

      update_data(status: STATUSES[:completed], reason: reason)
    end

    # Delete the scheduled event. Use this with caution, as it cannot be undone.
    # @param reason [String, nil] the audit log reason for deleting the scheduled event.
    # @return [void]
    def delete(reason: nil)
      API::Server.delete_scheduled_event(@bot.token, @server.id, @id, reason)
      @server.scheduled_events.delete(@id)
    end

    # Overwrite the existing reccurence rule for the scheduled event or add one.
    # @example This event will occur annually on December 25th.
    #   scheduled_event.set_recurrence_rule do |builder|
    #     builder.interval = 1
    #     builder.by_month_day = 25
    #     builder.by_month = :december
    #     builder.frequency = :yearly
    #     builder.starts_at = :replace_with_time
    #   end
    # @example This event will occur on every weekday.
    #   scheduled_event.set_recurrence_rule do |builder|
    #     builder.interval = 1
    #     builder.frequency = :daily
    #     builder.by_weekday = (0..4).to_a
    #     builder.starts_at = :replace_with_time
    #   end
    # @example This event will occur on every other tuesday.
    #   scheduled_event.set_recurrence_rule do |builder|
    #     builder.interval = 2
    #     builder.frequency = :weekly
    #     builder.by_weekday = :wednesday
    #     builder.starts_at = :replace_with_time
    #   end
    # @example This event will occur monthly on the fourth wednesday.
    #   scheduled_event.set_recurrence_rule do |builder|
    #     builder.interval = 1
    #     builder.frequency = :monthly
    #     builder.by_n_weekday(week: 4, day: :wednesday)
    #     builder.starts_at = :replace_with_time
    #   end
    # @yieldparam builder [RecurrenceRule::Builder] the builder for the reccurence rule to add or update.
    # @param reason [String, nil] the reason that will show up for modifying the event's reccurence rule.
    # @return [void]
    def update_recurrence_rule(reason: nil)
      yield((builder = RecurrenceRule::Builder.new))

      raise 'interval cannot be nil' unless builder.interval?

      raise 'starts_at cannot be nil' unless builder.starts_at?

      raise 'frequency cannot be nil' unless builder.frequency?

      update_data(recurrence_rule: builder.to_h, reason: reason)
    end

    # Set the entity type of the scheduled event. You must use this method
    #   instead of {#entity_type=} when setting the entity type to `:external`.
    # @param type [Symbol, Integer] the new entity type of the scheduled event.
    # @param location [String, nil] the new location of the scheduled event, or `nil`.
    # @param ends_at [Time, Date] the new time at when the scheduled event should end.
    # @param channel [Channel, Integer, String, nil] the new channel of the scheduled event.
    # @param reason [String, nil] the reason that will show up for modifying the scheduled event.
    def update_entity_type(type:, channel: :undef, location: :undef, ends_at: :undef, reason: nil)
      new_data = {
        reason: reason,
        entity_type: ENTITY_TYPES[type] || type,
        channel_id: channel == :undef ? :undef : channel&.resolve_id,
        entity_metadata: location == :undef ? :undef : { location: },
        scheduled_end_time: ends_at == :undef ? :undef : ends_at.iso8601
      }

      update_data(new_data)
    end

    # Get the total amount of users who are subscribed to the scheduled event.
    # @return [Integer] the total number of users who're currently subscribed to the scheduled event.
    # @note This method caches results for an unspecificed period of time. This means the count may **not** be accurate.
    def subscriber_count
      @subscriber_count ||= JSON.parse(API::Server.get_scheduled_event(@bot.token, @server.id, @id, true))['user_count']
    end

    alias_method :user_count, :subscriber_count

    # Get the users that are subscribed to the scheduled event.
    # @param limit [Integer, nil] the limit (`nil` for no limit) of how many subscribers to return.
    # @param member [true, false] whether to return subscribers as server members, where applicable.
    # @return [Array<User, Member>] the users or members that have subscribed to the scheduled event.
    def subscribers(limit: 100, member: false)
      get_users = proc do |limit_, after = nil|
        response = JSON.parse(API::Server.get_scheduled_event_users(@bot.token, @server.id, @id, limit_, member, nil, after))
        response.map { |data| data['member'] ? Member.new(data['member'], @server, @bot).tap { |m| @server&.cache_member(m) } : User.new(data['user'], @bot) }
      end

      # Can be done without pagination.
      return get_users.call(limit) if limit && limit <= 100

      paginator = Paginator.new(limit, :down) do |last_page|
        if last_page && last_page.count < 100
          []
        else
          get_users.call(100, last_page&.last&.id)
        end
      end

      paginator.to_a
    end

    alias_method :users, :subscribers

    # @!visibility private
    def inspect
      "<ScheduledEvent id=#{@id} server=#{@server} name=\"#{@name}\" creator_id=#{@creator_id} status=#{@status} starts_at=#{@starts_at} ends_at=#{@ends_at}>"
    end

    # @!visibility private
    def from_other(new_data)
      @name = new_data['name']
      @status = new_data['status']
      @cover_id = new_data['image']
      @entity_type = new_data['entity_type']
      @description = new_data['description']
      @entity_id = new_data['entity_id']&.to_i
      @channel_id = new_data['channel_id']&.to_i
      @starts_at = Time.iso8601(new_data['scheduled_start_time'])
      @location = new_data['entity_metadata']['location'] if new_data['entity_metadata']
      @ends_at = Time.iso8601(new_data['scheduled_end_time']) if new_data['scheduled_end_time']
      @recurrence_rule = RecurrenceRule.new(new_data['recurrence_rule'], @bot) if new_data['recurrence_rule']
    end

    # @!visibility private
    def update_data(new_data)
      from_other(JSON.parse(API::Server.update_scheduled_event(@bot.token,
                                                               @server.id, @id,
                                                               new_data[:name] || :undef,
                                                               new_data[:image] || :undef,
                                                               new_data[:status] || :undef,
                                                               new_data[:entity_type] || :undef,
                                                               new_data[:privacy_level] || :undef,
                                                               new_data[:scheduled_end_time] || :undef,
                                                               new_data[:scheduled_start_time] || :undef,
                                                               new_data.key?(:channel_id) ? new_data[:channel_id] : :undef,
                                                               new_data.key?(:description) ? new_data[:description] : :undef,
                                                               new_data.key?(:entity_metadata) ? new_data[:entity_metadata] : :undef,
                                                               new_data.key?(:recurrence_rule) ? new_data[:recurrence_rule] : :undef,
                                                               new_data[:reason])))
    end

    # Represents how frequently a scheduled event will repeat.
    class RecurrenceRule
      # Map of weekdays.
      WEEKDAYS = {
        monday: 0,
        tuesday: 1,
        wednesday: 2,
        thursday: 3,
        friday: 4,
        saturday: 5,
        sunday: 6
      }.freeze

      # Map of frequencies.
      FREQUENCIES = {
        yearly: 0,
        monthly: 1,
        weekly: 2,
        daily: 3
      }.freeze

      # Map of months.
      MONTHS = {
        january: 1,
        february: 2,
        march: 3,
        april: 4,
        may: 5,
        june: 6,
        july: 7,
        august: 8,
        september: 9,
        october: 10,
        november: 11,
        december: 12
      }.freeze

      # The days of the week on a specific week to recur on.
      # @!attribute week
      #   @return [Integer] The week (1-5) to recur on.
      # @!attribute day
      #   @return [Integer] The day (0-6) of the week to recur on.
      WeeklyDay = Struct.new('WeeklyDay', :week, :day)

      # @return [Integer, nil] the amount of times that the event can recur before stopping.
      attr_reader :count

      # @return [Array<Integer>] the specific months the event can recur on.
      attr_reader :by_month

      # @return [Time, nil] the time at when the reccurence interval will end.
      attr_reader :ends_at

      # @return [Time] the time at when the reccurence interval will start.
      attr_reader :starts_at

      # @return [Array<Integer>] the specific days of the week the event can recur on.
      attr_reader :by_weekday

      # @return [Integer] The spacing between the events, defined by the frequency.
      attr_reader :interval

      # @return [Integer] how often the reccurence interval will occur, e.g. yearly, monthly.
      attr_reader :frequency

      # @return [Array<Integer>] the specific days within the year (1-364) to recur on.
      attr_reader :by_year_day

      # @return [Array<WeeklyDay>] the specific days within a specific week to recur on.
      attr_reader :by_n_weekday

      # @return [Array<Integer>] the specific dates within a month to recur on.
      attr_reader :by_month_day

      # @!visibility private
      def initialize(data, bot)
        @bot = bot
        @count = data['count']
        @by_month = data['by_month'] || []
        @ends_at = Time.iso8601(data['end']) if data['end']
        @starts_at = Time.iso8601(data['start'])
        @by_weekday = data['by_weekday'] || []
        @interval = data['interval']
        @frequency = data['frequency']
        @by_year_day = data['by_year_day'] || []
        @by_n_weekday = data['by_n_weekday']&.map { |by| WeeklyDay.new(by['n'], by['day']) } || []
        @by_month_day = data['by_month_day'] || []
      end

      # @!visibility private
      def to_h
        {
          count: @count,
          interval: @interval,
          frequency: @frequency,
          end: @ends_at&.iso8601,
          start: @starts_at&.iso8601,
          by_month: @by_month.any? ? @by_month : nil,
          by_weekday: @by_weekday.any? ? @by_weekday : nil,
          by_year_day: @by_year_day.any? ? @by_year_day : nil,
          by_month_day: @by_month_day.any? ? @by_month_day : nil,
          by_n_weekday: @by_n_weekday.any? ? @by_n_weekday.map { |by| { n: by.week, day: by.day } } : nil
        }
      end

      # @!method yearly?
      #   @return [true, false] whether the event repeat on a yearly basis.
      # @!method monthly?
      #   @return [true, false] whether the event repeat on a monthly basis.
      # @!method weekly?
      #   @return [true, false] whether the event repeat on a weekly basis.
      # @!method daily?
      #   @return [true, false] whether the event repeat on a daily basis.
      FREQUENCIES.each do |name, value|
        define_method("#{name}?") do
          @frequency == value
        end
      end

      # Builder for the reccurence rule.
      class Builder
        # @overload interval=(value)
        #   @param value [Integer] the spacing between the events, defined by the frequency.
        #   @return [void]
        attr_writer :interval

        # @overload frequency=(value)
        #   @param value [Integer, String] how frequently the scheduled event should occur.
        #   @return [void]
        attr_writer :frequency

        # @overload starts_at=(value)
        #   @param value [Time, #iso8601] the time at when the reccurence interval will begin.
        #   @return [void]
        attr_writer :starts_at

        # @!visibility private
        def initialize
          @interval = nil
          @frequency = nil
          @starts_at = nil
        end

        # Set the the specific days within the month to recur on.
        # @param monthly_days [Array<Integer>] the speific days within
        #   the month to recur on.
        # @return [void]
        def by_month_day=(monthly_days)
          @by_month_day = Array(monthly_days).map(&:to_i)
        end

        # Set the the specific months of the year to recur on.
        # @param months [Array<Integer, Symbol>, Integer, Symbol] the specific months
        #   of the year to recur on,  e.g. `:april`, `:july`, `:june`, etc.
        # @return [void]
        def by_month=(months)
          @by_month = Array(months).map { |month| MONTHS[month] || month }
        end

        # Set the specific days of the week to recur on.
        # @param weekdays [Array<Symbol, Integer>, Symbol, Integer] the specific days
        #   of the week to recur on, e.g. `:tuesday`, `:saturday`, etc.
        # @return [void]
        def by_weekday=(weekdays)
          @by_weekday = Array(weekdays).map { |day| WEEKDAYS[day] || day }
        end

        # Set the specific days for a specific week to recur on.
        # @param week [Integer] the week of the month (1-5) to recur on.
        # @param day [Integer, Symbol] the specific day of the week to recur on, e.g. `:april`.
        # @return [void]
        def by_n_weekday(week:, day:)
          (@by_n_weekday ||= []) << { n: week, day: WEEKDAYS[day] || day }
        end

        # @!visibility private
        # @return [true, false]
        def interval?
          !@interval.nil?
        end

        # @!visibility private
        # @return [true, false]
        def frequency?
          !@frequency.nil?
        end

        # @!visibility private
        # @return [true, false]
        def starts_at?
          !@starts_at.nil?
        end

        # @!visibility private
        def to_h
          {
            by_month: @by_month,
            by_weekday: @by_weekday,
            interval: @interval.to_i,
            by_n_weekday: @by_n_weekday,
            by_month_day: @by_month_day,
            start: @starts_at.utc.iso8601,
            frequency: FREQUENCIES[@frequency] || @frequency
          }
        end
      end
    end
  end
end
