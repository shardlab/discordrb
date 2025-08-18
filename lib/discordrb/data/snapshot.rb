# frozen_string_literal: true

module Discordrb
  # A partial and immutable copy of a message that has been forwarded.
  class Snapshot
    # @return [Integer] the message type of the message snapshot.
    attr_reader :type

    # @return [String] the text content of the message snapshot.
    attr_reader :content

    # @return [Array<Embed>] the embeds attached to the message snapshot.
    attr_reader :embeds

    # @return [Array<Attachment>] the files attached to the message snapshot.
    attr_reader :attachments

    # @return [Time] the time at which the message snapshot was created.
    attr_reader :created_at

    # @return [Time, nil] the time at which the message snapshot was edited.
    attr_reader :edited_at

    # @return [Integer] the flags that have been set on the message snapshot.
    attr_reader :flags

    # @return [Array<User>] the users that were mentioned in the message snapshot.
    attr_reader :mentions

    # @return [Array<Component>] the interaction components associated with the message snapshot.
    attr_reader :components

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @type = data['type']
      @flags = data['flags'] || 0
      @content = data['content']
      @mention_roles = data['mention_roles']&.map(&:resolve_id) || []
      @embeds = data['embeds']&.map { |embed| Embed.new(embed, self) } || []
      @attachments = data['attachments']&.map { |file| Attachment.new(file, self, bot) } || []
      @created_at = data['timestamp'] ? Time.parse(data['timestamp']) : nil
      @edited_at = data['edited_timestamp'] ? Time.parse(data['edited_timestamp']) : nil
      @mentions = data['mentions']&.map { |mention| bot.ensure_user(mention) } || []
      @components = data['components']&.map { |component| Components.from_data(component, bot) } || []
    end

    # Check whether the message snapshot has been edited.
    # @return [true, false] whether the snapshot was edited or not.
    def edited?
      !@edited_at.nil?
    end

    # Check whether the message snapshot contains any custom emojis.
    # @return [true, false]  whether or not any emoji were used in the snapshot.
    def emojis?
      emojis.any?
    end

    # Get the custom emojis that were used in the message snapshot.
    # @return [Array<Emoji>] the emojis used in the message snapshot.
    def emojis
      return [] if @content.nil? || @content.empty?

      @emojis ||= @bot.parse_mentions(@content).select { |parsed| parsed.is_a?(Emoji) }
    end

    # Get the roles that were mentioned in the message snapshot.
    # @return [Array<Role>] the roles that were mentioned in the message snapshot.
    # @note this can only resolve roles in servers that the bot has access to via {Bot#servers}.
    def role_mentions
      return [] if @mention_roles.empty?

      return @role_mentions if @role_mentions

      roles = @bot.servers.values.flat_map(&:roles)

      @role_mentions = @mention_roles.filter_map { |id| roles.find { |r| r.id == id } }
    end

    # Get the buttons that were used in the message snapshot.
    # @return [Array<Components::Button>] the button components used in the message snapshot.
    def buttons
      buttons = @components.flat_map do |component|
        case component
        when Components::Button
          component
        when Components::ActionRow
          component.buttons
        end
      end

      buttons.compact
    end

    # @see Discordrb::Message::FLAGS
    Message::FLAGS.each do |name, value|
      define_method("#{name}?") do
        @flags.anybits?(value)
      end
    end
  end
end
