# frozen_string_literal: true

module Discordrb
  # A group of users that can manage applications.
  class Team
    include IDObject

    # @return [String] the name of the team.
    attr_reader :name

    # @return [Member] the owner of the team.
    attr_reader :owner

    # @return [String, nil] the hash of the team's icon.
    # @see #icon_url
    attr_reader :icon_id

    # @return [Array<Member>] the members that are a part of the team.
    attr_reader :members

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      @name = data['name']
      @icon_id = data['icon']
      @members = data['members'].map { |member| Member.new(member, self, bot) }
      @owner = @members.find { |member| member.user.id == data['owner_user_id'].to_i }
    end

    # Utility method to get a team's icon URL.
    # @param format [String] The URL will default to `webp`. You can otherwise specify one of `webp`, `jpg`, or `png` to override this.
    # @param size [Integer, nil] The URL will default to `4096`. You can otherwise specify any number that's a power of two to override this.
    # @return [String, nil] the URL to the icon image (`nil` if no image is set).
    def icon_url(format: 'webp', size: 4096)
      API.team_icon_url(@id, @icon_id, format, size) if @icon_id
    end

    # A member that has been invited to a team.
    class Member
      # @return [Symbol] the role of the team member.
      attr_reader :role

      # @return [Team] the team the member is a part of.
      attr_reader :team

      # @return [Integer] the membership state of the team member.
      attr_reader :state

      # @return [Integer] the user associated with the team member.
      attr_reader :user

      # @!visibility private
      def initialize(data, team, bot)
        @bot = bot
        @team = team
        @role = data['role'].to_sym
        @state = data['membership_state']
        @user = bot.ensure_user(data['user'])
      end

      # Whether the team member has been invited to the team, but hasn't accepted the invite yet.
      # @return [true, false] Whether the team member has been invited to the team but hasn't accepted yet.
      def pending?
        @state == 1
      end

      # Whether the team member is the owner of the team.
      # @return [true, false] If the team member is the owner.
      def owner?
        @team.owner == self
      end

      # @!method admin?
      #   @return [true, false] whether the team member is an admin.
      # @!method developer?
      #   @return [true, false] whether the team member is a developer.
      # @!method read_only?
      #   @return [true, false] whether the team member is a read-only developer.
      %i[admin developer read_only].each do |role|
        define_method("#{role}?") do
          @role == role
        end
      end

      # Comparison based off of user ID and team ID.
      # @param other [Member, Object] The object to compare against.
      # @return [true, false] Whether or not the two objects are equivalent.
      def ==(other)
        return false unless other.is_a?(Member)

        return false unless @team == other.team

        Discordrb.id_compare?(other.user.id, @user.id)
      end

      alias_method :eql?, :==
    end
  end
end
