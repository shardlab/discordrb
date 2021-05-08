# frozen_string_literal: true

module Discordrb
  # Base class for interaction objects.
  class Interaction
    # Interaction types.
    # @see https://discord.com/developers/docs/interactions/slash-commands#interaction-interactiontype
    TYPES = {
      ping: 1,
      command: 2
    }.freeze

    # Interaction response types.
    # @see https://discord.com/developers/docs/interactions/slash-commands#interaction-response-interactioncallbacktype
    CALLBACK_TYPES = {
      pong: 1,
      channel_message: 4,
      deferred_message: 5
    }.freeze

    # @return [User] The user that initiated the interaction.
    attr_reader :user

    # @return [Integer, nil] The ID of the server this interaction originates from.
		attr_reader :server_id

    # @return [Integer] The ID of the channel this interaction originates from.
		attr_reader :channel_id

    # @return [Integer] The ID of this interaction.
		attr_reader :id

    # @return [Integer] The ID of the application associated with this interaction.
		attr_reader :application_id

    # @return [String] The interaction token.
		attr_reader :token

    # @!visibility private
    # @return [Integer] Currently pointless
		attr_reader :version

    # @return [Integer] The type of this interaction.
    # @see TYPES
		attr_reader :type

    # @!visibility private
    def initialize(data, bot)
      @bot = bot

      @id = data['id'].to_i
      @application_id = data['application_id'].to_i
      @type = data['type']
      @data = data['data']
      @server_id = data['guild_id']&.to_i
      @channel_id = data['channel_id']&.to_i
      @user = if data['member']
                InteractionMember.new(data['member'], @server_id, bot)
              else
                bot.ensure_user(data['user'])
              end
      @token = data['token']
      @version = data['version']
    end

    # Respond to the creation of this interaction. An interaction must be responded to or deferred,
    # The response may be modified with {Interaction#edit_response} or deleted with {Interaction#delete_response}.
    # Further messages can be sent with {Interaction#send_message}.
    # @param content [String] The content of the message.
    # @param tts [true, false]
    # @param embeds [Array<Hash, Webhooks::Embed>] The embeds for the message.
    # @param allowed_mentions [Hash, AllowedMentions] Mentions that can ping on this message.
    # @param flags [Integer] Message flags.
    # @param ephemeral [true, false] Whether this message should only be visible to the interaction initiator.
    # @yieldparam builder [Webhooks::Builder] An optional message builder. Arguments passed to the method overwrite builder data.
    def respond(content: nil, tts: nil, embeds: nil, allowed_mentions: nil, flags: 0, ephemeral: nil)
      flags |= 1 << 6 if ephemeral

      builder = Discordrb::Webhooks::Builder.new
      yield builder if block_given?

      data = builder.to_json_hash.merge({ content: content, embeds: embeds, allowed_mentions: allowed_mentions }.compact)

      Discordrb::API::Interaction.create_interaction_response(@token, @id, CALLBACK_TYPES[:channel_message], data[:content], tts, data[:embeds], data[:allowed_mentions], flags)
      nil
    end

    # Defer an interaction, setting a temporary response that can be later overriden by {Interaction#send_message}. 
    # This method is used when you want to use a single message for your response but require additional processing time, or to simply ack
    # an interaction so an error is not displayed.
    # @param flags [Integer] Message flags.
    # @param ephemeral [true, false] Whether this message should only be visible to the interaction initiator.
    def defer(flags: 0, ephemeral: true)
      flags |= 1 << 6 if ephemeral

      Discordrb::API::Interaction.create_interaction_response(@token, @id, CALLBACK_TYPES[:deferred_message], nil, nil, nil, nil, flags)
      nil
    end

    # Edit the original response to this interaction.
    # @param content [String] The content of the message.
    # @param embeds [Array<Hash, Webhooks::Embed>] The embeds for the message.
    # @param allowed_mentions [Hash, AllowedMentions] Mentions that can ping on this message.
    # @return [InteractionMessage] The updated response message.
    # @yieldparam builder [Webhooks::Builder] An optional message builder. Arguments passed to the method overwrite builder data.
    def edit_response(content: nil, embeds: nil, allowed_mentions: nil)
      builder = Discordrb::Webhooks::Builder.new
      yield builder if block_given?

      data = builder.to_json_hash.merge({ content: content, embeds: embeds, allowed_mentions: allowed_mentions }.compact)
      resp = Discordrb::API::Interaction.edit_original_interaction_response(@token, @application_id, data[:content], data[:embeds], data[:allowed_mentions])

      InteractionMessage.new(JSON.parse(resp), @interaction, @bot)
    end

    # Delete the original interaction response.
    def delete_response
      Discordrb::API::Interaction.delete_original_interaction_response(@token, @application_id)
    end

    # @param content [String] The content of the message.
    # @param tts [true, false]
    # @param embeds [Array<Hash, Webhooks::Embed>] The embeds for the message.
    # @param allowed_mentions [Hash, AllowedMentions] Mentions that can ping on this message.
    # @param flags [Integer] Message flags.
    # @param ephemeral [true, false] Whether this message should only be visible to the interaction initiator.
    # @yieldparam builder [Webhooks::Builder] An optional message builder. Arguments passed to the method overwrite builder data.
    def send_message(content: nil, embeds: nil, tts: false, allowed_mentions: nil, flags: 0, ephemeral: false)
      flags |= 64 if ephemeral
      
      builder = Discordrb::Webhooks::Builder.new
      yield builder if block_given?

      data = builder.to_json_hash.merge({ content: content, embeds: embeds, allowed_mentions: allowed_mentions }.compact)
    
      resp = Discordrb::API::Webhook.token_execute_webhook(@token, @application_id, true, data[:content], nil, nil, data[:tts], nil, data[:embeds], data[:allowed_mentions], flags)
      InteractionMessage.new(JSON.parse(resp), @interaction, @bot)
    end

    # @param message [String, Integer, InteractionMessage, Message] The message created by this interaction to be edited.
    # @param content [String] The message content.
    # @param embeds [Array<Hash, Webhooks::Embed>] The embeds for the message.
    # @param allowed_mentions [Hash, AllowedMentions] Mentions that can ping on this message.
    # @yieldparam builder [Webhooks::Builder] An optional message builder. Arguments passed to the method overwrite builder data.
    def edit_message(message, content: nil, embeds: nil, allowed_mentions: nil)
      builder ||= Discordrb::Webhooks::Builder.new
      yield builder if block_given?

      data = builder.to_json_hash.merge({ content: content, embeds: embeds, allowed_mentions: allowed_mentions }.compact)
    
      resp = Discordrb::API::Webhook.token_edit_message(@interaction.token, @interaction.application_id, message.resolve_id, data[:content], data[:embeds], data[:allowed_mentions])
      InteractionMessage.new(JSON.parse(resp), @interaction, @bot)
    end

    # @param message [Integer, String, InteractionMessage, Message] The message created by this interaction to be deleted.
    def delete_message(message)
      Discordrb::API::Webhook.token_delete_message(@interaction.token, @interaction.application_id, message.resolve_id)
      nil
    end

    # @return [Server, nil] This will be nil for interactions that occur in DM channels or servers where the bot
    #   does not have the `bot` scope.
    def server
      @bot.server(@server_id)
    end

    # @return [Channel, nil]
    # @raise [Errors::NoPermission] When the bot is not in the server associated with this interaction.
    def channel
      @bot.channel(@channel_id)
    end
  end

  # A member partial for interactions.
  class InteractionMember < DelegateClass(User)
    include IDObject
    include MemberAttributes

    # @return [Array<Integer>] the IDs of the roles this member has.
    attr_reader :roles

    # @!visibility private
    def initialize(data, server_id, bot)
      @bot = bot
      @server_id = server_id

      @user = bot.ensure_user(data['user'])
      super @user

      @nick = data['nick']
      @joined_at = data['joined_at']
      @boosting_since = data['premium_since'] ? Time.parse(data['premium_since']) : nil
      @permissions = Permissions.new(data['permissions'])
      @mute = data['mute']
      @deaf = data['deaf']
    end

    # Attempt to create a member object
    # @raise [Errors::NoPermission] Will raise when the application has not been granted the `bot` scope in the
    #   server where this interaction originates.
    # @return [Member]
    def to_member
      server = @bot.server(@server_id)
      
      raise Discordrb::Errors::NoPermission, 'Unauthorized to access information for this server' if server.nil?

      server.member(@user.id)
    end

    # @return [String] the name the user displays as (nickname if they have one, username otherwise)
    def display_name
      nickname || username
    end
  end

  # A message partial for interactions.
  class InteractionMessage
    include IDObject

    # @return [Interaction] The interaction that created this message.
    attr_reader :interaction

    # @return [String, nil] The content of the message.
		attr_reader :content

    # @return [true, false] Whether this message is pinned in the channel it belongs to.
		attr_reader :pinned

    # @return [true, false]
		attr_reader :tts

    # @return [Time]
		attr_reader :timestamp

    # @return [Time, nil]
		attr_reader :edited_timestamp

    # @return [true, false]
		attr_reader :edited

    # @return [Integer]
		attr_reader :id

    # @return [User] The user of the application.
		attr_reader :author

    # @return 
		attr_reader :attachments
		attr_reader :embeds
		attr_reader :mentions
		attr_reader :flags
    
    # @!visibility private
    def initialize(data, interaction, bot)
      @bot = bot
      @interaction = interaction
      @content = data['content']
      @channel_id = data['channel_id'].to_i
      @pinned = data['pinned']
      @tts = data['tts']

      @message_reference = data['message_reference']

      @server_id = data['guild_id']&.to_i

      @timestamp = Time.parse(data['timestamp']) if data['timestamp']
      @edited_timestamp = data['edited_timestamp'].nil? ? nil : Time.parse(data['edited_timestamp'])
      @edited = !@edited_timestamp.nil?

      @id = data['id'].to_i
      @author = bot.ensure_user(data['author'])

      @attachments = []
      @attachments = data['attachments'].map { |e| Attachment.new(e, self, @bot) } if data['attachments']
      
      @embeds = []
      @embeds = data['embeds'].map { |e| Embed.new(e, self) } if data['embeds']

      @mentions = []
      
      data['mentions']&.each do |element|
        @mentions << bot.ensure_user(element)
      end

      @mention_roles = data['mention_roles']
      @mention_everyone = data['mention_everyone']
      @flags = data['flags']
      @pinned = data['pinned']
    end

    # @return [Member, nil] This will return nil if the bot does not have access to the
    #   server the interaction originated in.
    def member
      server&.member(@user.id)
    end

    # @return [Server, nil] This will return nil if the bot does not have access to the
    #   server the interaction originated in.
    def server
      @bot.server(@server_id)
    end

    # Respond to this message.
    # @param (see Interaction#send_message)
    # @yieldparam (see Interaction#send_message)
    def respond(content: nil, embeds: nil, allowed_mentions: nil, flags: 0, ephemeral: true, &block)
      @interaction.respond(content: content, embeds: embeds, allowed_mentions: allowed_mentions, flags: flags, ephemeral: ephemeral, &block)
    end

    # Delete this message.
    def delete
      @interaction.delete_message(@id)
    end

    # Edit this message's data.
    # @param content (see Interaction#send_message)
    # @param embeds (see Interaction#send_message)
    # @param allowed_mentions (see Interaction#send_message)
    # @yieldparam (see Interaction#send_message)
    def edit(content: nil, embeds: nil, allowed_mentions: nil, &block)
      @interaction.edit_message(@id, content: content, embeds: embeds, allowed_mentions: allowed_mentions, &block)
    end

    # @!visibility private
    def inspect
      "<IntreractionMessage content=#{@content.inspect} embeds=#{@embeds.inspect} channel_id=#{@channel_id} server_id=#{@server_id} author=#{@author.inspect}>"
    end
  end
end
