# frozen_string_literal: true

module Discordrb
  # A message on Discord that was sent to a text channel
  class Message
    include IDObject

    # Map of message flags.
    FLAGS = {
      crossposted: 1 << 0,
      crosspost: 1 << 1,
      suppress_embeds: 1 << 2,
      source_message_deleted: 1 << 3,
      urgent: 1 << 4,
      thread: 1 << 5,
      ephemeral: 1 << 6,
      loading: 1 << 7,
      failed_to_mention_roles: 1 << 8,
      suppress_notifications: 1 << 12,
      voice_message: 1 << 13,
      snapshot: 1 << 14,
      uikit_components: 1 << 15
    }.freeze

    # Map of message types.
    TYPES = {
      default: 0,
      recipient_add: 1,
      recipient_remove: 2,
      call: 3,
      channel_name_change: 4,
      channel_icon_change: 5,
      channel_pinned_message: 6,
      server_member_join: 7,
      server_boost: 8,
      server_boost_tier_one: 9,
      server_boost_tier_two: 10,
      server_boost_tier_three: 11,
      channel_follow_add: 12,
      server_discovery_disqualified: 14,
      server_discovery_requalified: 15,
      server_discovery_grace_period_initial_warning: 16,
      server_discovery_grace_period_final_warning: 17,
      thread_created: 18,
      reply: 19,
      chat_input_command: 20,
      thread_starter_message: 21,
      server_invite_reminder: 22,
      context_menu_command: 23,
      automod_action: 24,
      role_subscription_purchase: 25,
      interaction_premium_upsell: 26,
      stage_start: 27,
      stage_end: 28,
      stage_speaker: 29,
      stage_raise_hand: 30,
      stage_topic: 31,
      server_application_premium_subscription: 32,
      server_incident_alert_mode_enabled: 36,
      server_incident_alert_mode_disabled: 37,
      server_incident_report_raid: 38,
      server_incident_report_false_alarm: 39,
      purchase_notification: 44,
      poll_result: 46,
      changelog: 47,
      server_join_request_accepted: 52,
      server_join_request_rejected: 53,
      server_join_request_withdrawn: 54,
      report_to_mod_deleted_message: 58,
      report_to_mod_timeout_user: 59,
      report_to_mod_kick_user: 60,
      report_to_mod_ban_user: 61,
      report_to_mod_closed_report: 62,
      server_emoji_added: 63
    }.freeze

    # @return [String] the content of this message.
    attr_reader :content
    alias_method :text, :content
    alias_method :to_s, :content

    # @return [Channel] the channel in which this message was sent.
    attr_reader :channel

    # @return [Time] the timestamp at which this message was sent.
    attr_reader :timestamp

    # @return [Time] the timestamp at which this message was edited. `nil` if the message was never edited.
    attr_reader :edited_timestamp
    alias_method :edit_timestamp, :edited_timestamp

    # @return [Array<User>] the users that were mentioned in this message.
    attr_reader :mentions

    # @return [Array<Attachment>] the files attached to this message.
    attr_reader :attachments

    # @return [Array<Embed>] the embed objects contained in this message.
    attr_reader :embeds

    # @return [Array<Reaction>] the reaction objects contained in this message.
    attr_reader :reactions

    # @return [true, false] whether the message used Text-To-Speech (TTS) or not.
    attr_reader :tts
    alias_method :tts?, :tts

    # @return [String] used for validating a message was sent.
    attr_reader :nonce

    # @return [true, false] whether the message was edited or not.
    attr_reader :edited
    alias_method :edited?, :edited

    # @return [true, false] whether the message mentioned everyone or not.
    attr_reader :mention_everyone
    alias_method :mention_everyone?, :mention_everyone
    alias_method :mentions_everyone?, :mention_everyone

    # @return [true, false] whether the message is pinned or not.
    attr_reader :pinned
    alias_method :pinned?, :pinned

    # @return [Integer] what the type of the message is
    attr_reader :type

    # @return [Integer, nil] the webhook ID that sent this message, or `nil` if it wasn't sent through a webhook.
    attr_reader :webhook_id

    # @return [Array<Component>] Interaction components for this message.
    attr_reader :components

    # @return [Integer] flags set on the message.
    attr_reader :flags

    # @return [Channel, nil] The thread that was started from this message, or nil.
    attr_reader :thread

    # @return [Time, nil] the time at when this message was pinned. Only present on messages fetched via {Channel#pins}.
    attr_reader :pinned_at

    # @return [Call, nil] the call in a private channel that prompted this message.
    attr_reader :call

    # @return [Array<Snapshot>] the message snapshots included in this message.
    attr_reader :snapshots

    # @!visibility private
    def initialize(data, bot)
      @bot = bot
      @id = data['id'].to_i
      @content = data['content']
      @channel = bot.channel(data['channel_id'].to_i)
      @pinned = data['pinned']
      @type = data['type']
      @tts = data['tts']
      @nonce = data['nonce']
      @mention_everyone = data['mention_everyone']
      @webhook_id = data['webhook_id']&.to_i

      @referenced_message = Message.new(data['referenced_message'], bot) if data['referenced_message']
      @message_reference = data['message_reference']

      if data['author']
        if @webhook_id
          # This is a webhook user! It would be pointless to try to resolve a member here, so we just create
          # a User and return that instead.
          Discordrb::LOGGER.debug("Webhook user: #{data['author']['id']}")
          @author = User.new(data['author'].merge({ '_webhook' => true }), @bot)
        elsif @channel.private?

          # Turn the message user into a recipient - we can't use the channel recipient
          # directly because the bot may also send messages to the channel
          @author = Recipient.new(bot.user(data['author']['id'].to_i), @channel, bot)
        else
          @author_id = data['author']['id'].to_i
        end
      end

      @timestamp = Time.parse(data['timestamp']) if data['timestamp']
      @edited_timestamp = data['edited_timestamp'].nil? ? nil : Time.parse(data['edited_timestamp'])
      @edited = !@edited_timestamp.nil?

      @emoji = []

      @reactions = []

      data['reactions']&.each do |element|
        @reactions << Reaction.new(element)
      end

      @mentions = []

      data['mentions']&.each do |element|
        @mentions << bot.ensure_user(element)
      end

      @mention_roles = data['mention_roles']&.map(&:to_i) || []

      @attachments = []
      @attachments = data['attachments'].map { |e| Attachment.new(e, self, @bot) } if data['attachments']

      @embeds = []
      @embeds = data['embeds'].map { |e| Embed.new(e, self) } if data['embeds']

      @components = []
      @components = data['components'].map { |component_data| Components.from_data(component_data, @bot) } if data['components']

      @flags = data['flags'] || 0

      @thread = data['thread'] ? @bot.ensure_channel(data['thread']) : nil

      @pinned_at = data['pinned_at'] ? Time.parse(data['pinned_at']) : nil

      @call = data['call'] ? Call.new(data['call'], @bot) : nil

      @snapshots = data['message_snapshots']&.map { |snapshot| Snapshot.new(snapshot['message'], @bot) } || []
    end

    # @return [Member, User] the user that sent this message. (Will be a {Member} most of the time, it should only be a
    #   {User} for old messages when the author has left the server since then)
    def author
      return @author if @author

      unless @channel.private?
        @author = @channel.server.member(@author_id)
        Discordrb::LOGGER.debug("Member with ID #{@author_id} not cached (possibly left the server).") if @author.nil?
      end

      @author ||= @bot.user(@author_id)
    end

    alias_method :user, :author
    alias_method :writer, :author

    # @return [Server, nil] the server this message was sent in. If this message was sent in a PM channel, it will be nil.
    # @raise [Discordrb::Errors::NoPermission] This can happen when receiving interactions for servers in which the bot is not
    #   authorized with the `bot` scope.
    def server
      return if @channel.private?

      @server ||= @channel.server
    end

    # Get the roles that were mentioned in this message.
    # @return [Array<Role>] the roles that were mentioned in this message.
    # @raise [Discordrb::Errors::NoPermission] This can happen when receiving interactions for servers in which the bot is not
    #   authorized with the `bot` scope.
    def role_mentions
      return [] if @channel.private? || @mention_roles.empty?

      @role_mentions ||= @mention_roles.map { |id| server.role(id) }
    end

    # Replies to this message with the specified content.
    # @deprecated Please use {#respond}.
    # @param content [String] The content to send. Should not be longer than 2000 characters or it will result in an error.
    # @return (see #respond)
    # @see Channel#send_message
    def reply(content)
      @channel.send_message(content)
    end

    # Responds to this message as an inline reply.
    # @param content [String] The content to send. Should not be longer than 2000 characters or it will result in an error.
    # @param tts [true, false] Whether or not this message should be sent using Discord text-to-speech.
    # @param embed [Hash, Discordrb::Webhooks::Embed, nil] The rich embed to append to this message.
    # @param attachments [Array<File>] Files that can be referenced in embeds via `attachment://file.png`
    # @param allowed_mentions [Hash, Discordrb::AllowedMentions, false, nil] Mentions that are allowed to ping on this message. `false` disables all pings
    # @param mention_user [true, false] Whether the user that is being replied to should be pinged by the reply.
    # @param components [View, Array<Hash>] Interaction components to associate with this message.
    # @param flags [Integer] Flags for this message. Currently only SUPPRESS_EMBEDS (1 << 2) and SUPPRESS_NOTIFICATIONS (1 << 12) can be set.
    # @return (see #respond)
    def reply!(content, tts: false, embed: nil, attachments: nil, allowed_mentions: {}, mention_user: false, components: nil, flags: 0)
      allowed_mentions = { parse: [] } if allowed_mentions == false
      allowed_mentions = allowed_mentions.to_hash.transform_keys(&:to_sym)
      allowed_mentions[:replied_user] = mention_user

      respond(content, tts, embed, attachments, allowed_mentions, self, components, flags)
    end

    # (see Channel#send_message)
    def respond(content, tts = false, embed = nil, attachments = nil, allowed_mentions = nil, message_reference = nil, components = nil, flags = 0)
      @channel.send_message(content, tts, embed, attachments, allowed_mentions, message_reference, components, flags)
    end

    # Edits this message to have the specified content instead.
    # You can only edit your own messages.
    # @param new_content [String] the new content the message should have.
    # @param new_embeds [Hash, Discordrb::Webhooks::Embed, Array<Hash>, Array<Discordrb::Webhooks::Embed>, nil] The new embeds the message should have. If `nil` the message will be changed to have no embeds.
    # @param new_components [View, Array<Hash>] The new components the message should have. If `nil` the message will be changed to have no components.
    # @param flags [Integer] Flags for this message. Currently only SUPPRESS_EMBEDS (1 << 2) can be edited.
    # @return [Message] the resulting message.
    def edit(new_content, new_embeds = nil, new_components = nil, flags = 0)
      new_embeds = (new_embeds.instance_of?(Array) ? new_embeds.map(&:to_hash) : [new_embeds&.to_hash]).compact
      new_components = new_components.to_a

      response = API::Channel.edit_message(@bot.token, @channel.id, @id, new_content, :undef, new_embeds, new_components, flags)
      Message.new(JSON.parse(response), @bot)
    end

    # Deletes this message.
    # @return [nil]
    def delete(reason = nil)
      API::Channel.delete_message(@bot.token, @channel.id, @id, reason)
      nil
    end

    # Pins this message
    # @return [nil]
    def pin(reason = nil)
      API::Channel.pin_message(@bot.token, @channel.id, @id, reason)
      @pinned = true
      nil
    end

    # Unpins this message
    # @return [nil]
    def unpin(reason = nil)
      API::Channel.unpin_message(@bot.token, @channel.id, @id, reason)
      @pinned = false
      nil
    end

    # Crossposts a message in a news channel.
    # @return [Message] the updated message object.
    def crosspost
      response = API::Channel.crosspost_message(@bot.token, @channel.id, @id)
      Message.new(JSON.parse(response), @bot)
    end

    # Add an {Await} for a message with the same user and channel.
    # @see Bot#add_await
    # @deprecated Will be changed to blocking behavior in v4.0. Use {#await!} instead.
    def await(key, attributes = {}, &block)
      @bot.add_await(key, Discordrb::Events::MessageEvent, { from: @author.id, in: @channel.id }.merge(attributes), &block)
    end

    # Add a blocking {Await} for a message with the same user and channel.
    # @see Bot#add_await!
    def await!(attributes = {}, &block)
      @bot.add_await!(Discordrb::Events::MessageEvent, { from: @author.id, in: @channel.id }.merge(attributes), &block)
    end

    # Add an {Await} for a reaction to be added on this message.
    # @see Bot#add_await
    # @deprecated Will be changed to blocking behavior in v4.0. Use {#await_reaction!} instead.
    def await_reaction(key, attributes = {}, &block)
      @bot.add_await(key, Discordrb::Events::ReactionAddEvent, { message: @id }.merge(attributes), &block)
    end

    # Add a blocking {Await} for a reaction to be added on this message.
    # @see Bot#add_await!
    def await_reaction!(attributes = {}, &block)
      @bot.add_await!(Discordrb::Events::ReactionAddEvent, { message: @id }.merge(attributes), &block)
    end

    # @return [true, false] whether this message was sent by the current {Bot}.
    def from_bot?
      @author&.current_bot?
    end

    # @return [true, false] whether this message has been sent over a webhook.
    def webhook?
      !@webhook_id.nil?
    end

    # @return [Array<Emoji>] the emotes that were used/mentioned in this message.
    def emoji
      return if @content.nil?
      return @emoji unless @emoji.empty?

      @emoji = @bot.parse_mentions(@content).select { |el| el.is_a? Discordrb::Emoji }
    end

    # Check if any emoji were used in this message.
    # @return [true, false] whether or not any emoji were used
    def emoji?
      emoji&.empty?
    end

    # Check if any reactions were used in this message.
    # @return [true, false] whether or not this message has reactions
    def reactions?
      !@reactions.empty?
    end

    # Returns the reactions made by the current bot or user.
    # @return [Array<Reaction>] the reactions
    def my_reactions
      @reactions.select(&:me)
    end

    # Removes embeds from the message
    # @return [Message] the resulting message.
    def suppress_embeds
      flags = @flags | (1 << 2)
      response = API::Channel.edit_message(@bot.token, @channel.id, @id, :undef, :undef, :undef, :undef, flags)
      Message.new(JSON.parse(response), @bot)
    end

    # Check if this message mentions a specific user or role.
    # @param target [Role, User, Member, Integer, String] The mention to match against.
    # @return [true, false] whether or not this message mentions the target.
    def mentions?(target)
      mentions = (@mentions + role_mentions)

      mentions << server if @mention_everyone

      mentions.any?(target.resolve_id)
    end

    # Reacts to a message.
    # @param reaction [String, #to_reaction] the unicode emoji or {Emoji}
    # @return [nil]
    def create_reaction(reaction)
      reaction = reaction.to_reaction if reaction.respond_to?(:to_reaction)
      API::Channel.create_reaction(@bot.token, @channel.id, @id, reaction)
      nil
    end

    alias_method :react, :create_reaction

    # Returns the list of users who reacted with a certain reaction.
    # @param reaction [String, #to_reaction] the unicode emoji or {Emoji}
    # @param limit [Integer] the limit of how many users to retrieve. `nil` will return all users
    # @example Get all the users that reacted with a thumbs up.
    #   thumbs_up_reactions = message.reacted_with("\u{1F44D}")
    # @return [Array<User>] the users who used this reaction
    def reacted_with(reaction, limit: 100)
      reaction = reaction.to_reaction if reaction.respond_to?(:to_reaction)
      reaction = reaction.to_s if reaction.respond_to?(:to_s)

      get_reactions = proc do |fetch_limit, after_id = nil|
        resp = API::Channel.get_reactions(@bot.token, @channel.id, @id, reaction, nil, after_id, fetch_limit)
        JSON.parse(resp).map { |d| User.new(d, @bot) }
      end

      # Can be done without pagination
      return get_reactions.call(limit) if limit && limit <= 100

      paginator = Paginator.new(limit, :down) do |last_page|
        if last_page && last_page.count < 100
          []
        else
          get_reactions.call(100, last_page&.last&.id)
        end
      end

      paginator.to_a
    end

    # Returns a hash of all reactions to a message as keys and the users that reacted to it as values.
    # @param limit [Integer] the limit of how many users to retrieve per distinct reaction emoji. `nil` will return all users
    # @example Get all the users that reacted to a message for a giveaway.
    #   giveaway_participants = message.all_reaction_users
    # @return [Hash<String => Array<User>>] A hash mapping the string representation of a
    #   reaction to an array of users.
    def all_reaction_users(limit: 100)
      all_reactions = @reactions.map { |r| { r.to_s => reacted_with(r, limit: limit) } }
      all_reactions.reduce({}, :merge)
    end

    # Deletes a reaction made by a user on this message.
    # @param user [User, String, Integer] the user or user ID who used this reaction
    # @param reaction [String, #to_reaction] the reaction to remove
    def delete_reaction(user, reaction)
      reaction = reaction.to_reaction if reaction.respond_to?(:to_reaction)
      API::Channel.delete_user_reaction(@bot.token, @channel.id, @id, reaction, user.resolve_id)
    end

    # Deletes this client's reaction on this message.
    # @param reaction [String, #to_reaction] the reaction to remove
    def delete_own_reaction(reaction)
      reaction = reaction.to_reaction if reaction.respond_to?(:to_reaction)
      API::Channel.delete_own_reaction(@bot.token, @channel.id, @id, reaction)
    end

    # Removes all reactions from this message.
    def delete_all_reactions
      API::Channel.delete_all_reactions(@bot.token, @channel.id, @id)
    end

    # The inspect method is overwritten to give more useful output
    def inspect
      "<Message content=\"#{@content}\" id=#{@id} timestamp=#{@timestamp} author=#{@author} channel=#{@channel}>"
    end

    # @return [String] a URL that a user can use to navigate to this message in the client
    def link
      "https://discord.com/channels/#{server&.id || '@me'}/#{@channel.id}/#{@id}"
    end

    alias_method :jump_link, :link

    # Whether or not this message was sent in reply to another message
    # @return [true, false]
    def reply?
      !@referenced_message.nil?
    end

    # @return [Message, nil] the Message this Message was sent in reply to.
    def referenced_message
      return @referenced_message if @referenced_message
      return nil unless @message_reference

      referenced_channel = @bot.channel(@message_reference['channel_id'])
      @referenced_message = referenced_channel&.message(@message_reference['message_id'])
    end

    # @return [Array<Components::Button>]
    def buttons
      results = @components.collect do |component|
        case component
        when Components::Button
          component
        when Components::ActionRow
          component.buttons
        end
      end

      results.flatten.compact
    end

    # to_message -> self or message
    # @return [Discordrb::Message]
    def to_message
      self
    end

    alias_method :message, :to_message

    FLAGS.each do |name, value|
      define_method("#{name}?") do
        @flags.anybits?(value)
      end
    end

    TYPES.each do |name, value|
      define_method("#{name}?") do
        @type == value
      end
    end

    # Convert this message to a hash that can be used to reference this message in a forward or a reply.
    # @param type [Integer, Symbol] The reference type to set. Can either be one of `:reply` or `:forward`.
    # @param must_exist [true, false] Whether to raise an error if this message was deleted when sending it.
    # @return [Hash] the message as a hash representation that can be used in a forwarded message or a reply.
    def to_reference(type: :reply, must_exist: true)
      type = (type == :reply ? 0 : 1) if type.is_a?(Symbol)

      { type: type, message_id: @id, channel_id: @channel.id, fail_if_not_exists: must_exist }
    end

    # Forward this message to another channel.
    # @param channel [Integer, String, Channel] The target channel to forward this message to.
    # @param must_exist [true, false] Whether to raise an error if this message was deleted when sending it.
    # @param timeout [Float, nil] The amount of time in seconds after which the message sent will be deleted.
    # @param flags [Integer, Symbol, Array<Integer, Symbol>] The message flags to set on the forwarded message.
    # @param nonce [String, Integer, nil] The 25 character optional nonce that should be used when forwarding this message.
    # @param enforce_nonce [true, false] Whether the provided nonce should be enforced and used for message de-duplication.
    # @return [Message, nil] the message that was created from forwarding this one, or `nil` if this is a temporary message.
    def forward(channel, must_exist: true, timeout: nil, flags: 0, nonce: nil, enforce_nonce: false)
      reference = to_reference(type: :forward, must_exist: must_exist)

      @bot.channel(channel).send_message!(reference: reference, timeout: timeout, flags: flags, nonce: nonce, enforce_nonce: enforce_nonce)
    end
  end
end
