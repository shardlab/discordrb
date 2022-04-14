# frozen_string_literal: true

require 'discordrb/webhooks/builder'
require 'discordrb/webhooks/view'

module Discordrb
  # A webhook on a server channel
  class Webhook
    include IDObject

    # @return [String] the webhook name.
    attr_reader :name

    # @return [Channel] the channel that the webhook is currently connected to.
    attr_reader :channel

    # @return [Server] the server that the webhook is currently connected to.
    attr_reader :server

    # @return [String, nil] the webhook's token, if this is an Incoming Webhook.
    attr_reader :token

    # @return [String] the webhook's avatar id.
    attr_reader :avatar

    # @return [Integer] the webhook's type (1: Incoming, 2: Channel Follower)
    attr_reader :type

    # Gets the user object of the creator of the webhook. May be limited to username, discriminator,
    # ID and avatar if the bot cannot reach the owner
    # @return [Member, User, nil] the user object of the owner or nil if the webhook was requested using the token.
    attr_reader :owner

    def initialize(data, bot)
      @bot = bot

      @name = data['name']
      @id = data['id'].to_i
      @channel = bot.channel(data['channel_id'])
      @server = @channel.server
      @token = data['token']
      @avatar = data['avatar']
      @type = data['type']

      # Will not exist if the data was requested through a webhook token
      return unless data['user']

      @owner = @server.member(data['user']['id'].to_i)
      return if @owner

      Discordrb::LOGGER.debug("Member with ID #{data['user']['id']} not cached (possibly left the server).")
      @owner = @bot.ensure_user(data['user'])
    end

    # Sets the webhook's avatar.
    # @param avatar [String, #read] The new avatar, in base64-encoded JPG format.
    def avatar=(avatar)
      update_webhook(avatar: avatarise(avatar))
    end

    # Deletes the webhook's avatar.
    def delete_avatar
      update_webhook(avatar: nil)
    end

    # Sets the webhook's channel
    # @param channel [Channel, String, Integer] The channel the webhook should use.
    def channel=(channel)
      update_webhook(channel_id: channel.resolve_id)
    end

    # Sets the webhook's name.
    # @param name [String] The webhook's new name.
    def name=(name)
      update_webhook(name: name)
    end

    # Updates the webhook if you need to edit more than 1 attribute.
    # @param data [Hash] the data to update.
    # @option data [String, #read, nil] :avatar The new avatar, in base64-encoded JPG format, or nil to delete the avatar.
    # @option data [Channel, String, Integer] :channel The channel the webhook should use.
    # @option data [String] :name The webhook's new name.
    # @option data [String] :reason The reason for the webhook changes.
    def update(data)
      # Only pass a value for avatar if the key is defined as sending nil will delete the
      data[:avatar] = avatarise(data[:avatar]) if data.key?(:avatar)
      data[:channel_id] = data[:channel].resolve_id
      data.delete(:channel)
      update_webhook(data)
    end

    # Deletes the webhook.
    # @param reason [String] The reason the webhook is being deleted.
    def delete(reason = nil)
      if token?
        API::Webhook.token_delete_webhook(@token, @id, reason)
      else
        API::Webhook.delete_webhook(@bot.token, @id, reason)
      end
    end

    # Execute a webhook.
    # @param content [String] The content of the message. May be 2000 characters long at most.
    # @param username [String] The username the webhook will display as. If this is not set, the default username set in the webhook's settings.
    # @param avatar_url [String] The URL of an image file to be used as an avatar. If this is not set, the default avatar from the webhook's
    # @param tts [true, false] Whether this message should use TTS or not. By default, it doesn't.
    # @param file [File] File to be sent together with the message. Mutually exclusive with embeds; a webhook message can contain
    #   either a file to be sent or embeds.
    # @param embeds [Array<Webhooks::Embed, Hash>] Embeds to attach to this message.
    # @param allowed_mentions [AllowedMentions, Hash] Mentions that are allowed to ping in the `content`.
    # @param wait [true, false] Whether Discord should wait for the message to be successfully received by clients, or
    #   whether it should return immediately after sending the message. If `true` a {Message} object will be returned.
    # @yield [builder] Gives the builder to the block to add additional steps, or to do the entire building process.
    # @yieldparam builder [Builder] The builder given as a parameter which is used as the initial step to start from.
    # @example Execute the webhook with kwargs
    #   client.execute(
    #     content: 'Testing',
    #     username: 'discordrb',
    #     embeds: [
    #       { timestamp: Time.now.iso8601, title: 'testing', image: { url: 'https://i.imgur.com/PcMltU7.jpg' } }
    #     ])
    # @example Execute the webhook with an already existing builder
    #   builder = Discordrb::Webhooks::Builder.new # ...
    #   client.execute(builder)
    # @example Execute the webhook by building a new message
    #   client.execute do |builder|
    #     builder.content = 'Testing'
    #     builder.username = 'discordrb'
    #     builder.add_embed do |embed|
    #       embed.timestamp = Time.now
    #       embed.title = 'Testing'
    #       embed.image = Discordrb::Webhooks::EmbedImage.new(url: 'https://i.imgur.com/PcMltU7.jpg')
    #     end
    #   end
    # @return [Message, nil] If `wait` is `true`, a {Message} will be returned. Otherwise this method will return `nil`.
    # @note This is only available to webhooks with publically exposed tokens. This excludes channel follow webhooks and webhooks retrieved
    #   via the audit log.
    def execute(content: nil, username: nil, avatar_url: nil, tts: nil, file: nil, embeds: nil, allowed_mentions: nil, wait: true, builder: nil, components: nil)
      raise Discordrb::Errors::UnauthorizedWebhook unless @token

      params = { content: content, username: username, avatar_url: avatar_url, tts: tts, file: file, embeds: embeds, allowed_mentions: allowed_mentions }

      builder ||= Webhooks::Builder.new
      view = Webhooks::View.new

      yield(builder, view) if block_given?

      data = builder.to_json_hash.merge(params.compact)
      components ||= view

      resp = API::Webhook.token_execute_webhook(@token, @id, wait, data[:content], data[:username], data[:avatar_url], data[:tts], data[:file], data[:embeds], data[:allowed_mentions], nil, components.to_a)

      Message.new(JSON.parse(resp), @bot) if wait
    end

    # Delete a message created by this webhook.
    # @param message [Message, String, Integer] The ID of the message to delete.
    def delete_message(message)
      raise Discordrb::Errors::UnauthorizedWebhook unless @token

      API::Webhook.token_delete_message(@token, @id, message.resolve_id)
    end

    # Edit a message created by this webhook.
    # @param message [Message, String, Integer] The ID of the message to edit.
    # @param content [String] The content of the message. May be 2000 characters long at most.
    # @param embeds [Array<Webhooks::Embed, Hash>] Embeds to be attached to the message.
    # @param allowed_mentions [AllowedMentions, Hash] Mentions that are allowed to ping in the `content`.
    # @param builder [Builder, nil] The builder to start out with, or nil if one should be created anew.
    # @yield [builder] Gives the builder to the block to add additional steps, or to do the entire building process.
    # @yieldparam builder [Webhooks::Builder] The builder given as a parameter which is used as the initial step to start from.
    # @return [Message] The updated message.
    # @param components [View, Array<Hash>] Interaction components to associate with this message.
    # @note When editing `allowed_mentions`, it will update visually in the client but not alert the user with a notification.
    def edit_message(message, content: nil, embeds: nil, allowed_mentions: nil, builder: nil, components: nil)
      raise Discordrb::Errors::UnauthorizedWebhook unless @token

      params = { content: content, embeds: embeds, allowed_mentions: allowed_mentions }.compact

      builder ||= Webhooks::Builder.new
      view ||= Webhooks::View.new

      yield(builder, view) if block_given?

      data = builder.to_json_hash.merge(params.compact)
      components ||= view

      resp = API::Webhook.token_edit_message(@token, @id, message.resolve_id, data[:content], data[:embeds], data[:allowed_mentions], components.to_a)
      Message.new(JSON.parse(resp), @bot)
    end

    # Utility function to get a webhook's avatar URL.
    # @return [String] the URL to the avatar image
    def avatar_url
      return API::User.default_avatar unless @avatar

      API::User.avatar_url(@id, @avatar)
    end

    # The `inspect` method is overwritten to give more useful output.
    def inspect
      "<Webhook name=#{@name} id=#{@id}>"
    end

    # Utility function to know if the webhook was requested through a webhook token, rather than auth.
    # @return [true, false] whether the webhook was requested by token or not.
    def token?
      @owner.nil?
    end

    private

    def avatarise(avatar)
      if avatar.respond_to? :read
        "data:image/jpg;base64,#{Base64.strict_encode64(avatar.read)}"
      else
        avatar
      end
    end

    def update_internal(data)
      @name = data['name']
      @avatar_id = data['avatar']
      @channel = @bot.channel(data['channel_id'])
    end

    def update_webhook(new_data)
      reason = new_data.delete(:reason)
      data = JSON.parse(if token?
                          API::Webhook.token_update_webhook(@token, @id, new_data, reason)
                        else
                          API::Webhook.update_webhook(@bot.token, @id, new_data, reason)
                        end)
      # Only update cache if API call worked
      update_internal(data) if data['name']
    end
  end
end
