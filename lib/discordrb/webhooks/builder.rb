# frozen_string_literal: true

require 'discordrb/webhooks/embeds'

module Discordrb::Webhooks
  # A class that acts as a builder for a webhook message object.
  class Builder
    def initialize(content: '', username: nil, avatar_url: nil, tts: false, file: nil, embeds: [], allowed_mentions: nil, poll: nil)
      @content = content
      @username = username
      @avatar_url = avatar_url
      @tts = tts
      @file = file
      @embeds = embeds
      @allowed_mentions = allowed_mentions
      @poll = poll
    end

    # The content of the message. May be 2000 characters long at most.
    # @return [String] the content of the message.
    attr_accessor :content

    # The username the webhook will display as. If this is not set, the default username set in the webhook's settings
    # will be used instead.
    # @return [String] the username.
    attr_accessor :username

    # The URL of an image file to be used as an avatar. If this is not set, the default avatar from the webhook's
    # settings will be used instead.
    # @return [String] the avatar URL.
    attr_accessor :avatar_url

    # Whether this message should use TTS or not. By default, it doesn't.
    # @return [true, false] the TTS status.
    attr_accessor :tts

    # Sets a file to be sent together with the message. Mutually exclusive with embeds; a webhook message can contain
    # either a file to be sent or an embed.
    # @param file [File] A file to be sent.
    def file=(file)
      raise ArgumentError, 'Embeds and files are mutually exclusive!' unless @embeds.empty?

      @file = file
    end

    # Adds an embed to this message.
    # @param embed [Embed] The embed to add.
    def <<(embed)
      raise ArgumentError, 'Embeds and files are mutually exclusive!' if @file

      @embeds << embed
    end

    # Convenience method to add an embed using a block-style builder pattern
    # @example Add an embed to a message
    #   builder.add_embed do |embed|
    #     embed.title = 'Testing'
    #     embed.image = Discordrb::Webhooks::EmbedImage.new(url: 'https://i.imgur.com/PcMltU7.jpg')
    #   end
    # @param embed [Embed, nil] The embed to start the building process with, or nil if one should be created anew.
    # @return [Embed] The created embed.
    def add_embed(embed = nil)
      embed ||= Embed.new
      yield(embed)
      self << embed
      embed
    end

    # Convenience method to add a poll using a block-style builder pattern
    # @example Add a poll to a message
    #   builder.add_poll do |poll|
    #     poll.question = 'Best Fruit?'
    #     poll.multiselect = false
    #     poll.duration = Time.now + (86_400 * 3)
    #     poll.answer(name: "Apple", emoji: "🍎")
    #     poll.answer(name: "Orange", emoji: "🍊")
    #     poll.answer(name: "Pomelo", emoji: "🍈")
    #   end
    # @param poll [Poll::Builder, Poll, Hash, nil] The poll to start the building process with, or nil if one should be created anew.
    # @return [Poll::Builder, Poll] The created poll.
    def add_poll(poll = nil)
      poll ||= Discordrb::Poll::Builder.new
      yield(poll) if block_given?
      @poll = poll
      poll
    end

    # @return [File, nil] the file attached to this message.
    attr_reader :file

    # @return [Array<Embed>] the embeds attached to this message.
    attr_reader :embeds

    # @return [Discordrb::AllowedMentions, Hash] Mentions that are allowed to ping in this message.
    # @see https://discord.com/developers/docs/resources/channel#allowed-mentions-object
    attr_accessor :allowed_mentions

    # @return [Poll, Poll::Builder, Hash, nil] The poll attached to this message.
    # @see https://discord.com/developers/docs/resources/poll#poll-create-request-object
    attr_accessor :poll

    # @return [Hash] a hash representation of the created message, for JSON format.
    def to_json_hash
      {
        content: @content,
        username: @username,
        avatar_url: @avatar_url,
        tts: @tts,
        embeds: @embeds.map(&:to_hash),
        allowed_mentions: @allowed_mentions&.to_hash,
        poll: @poll&.to_h
      }
    end

    # @return [Hash] a hash representation of the created message, for multipart format.
    def to_multipart_hash
      {
        content: @content,
        username: @username,
        avatar_url: @avatar_url,
        tts: @tts,
        file: @file,
        allowed_mentions: @allowed_mentions&.to_hash
      }
    end
  end
end
