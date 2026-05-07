# frozen_string_literal: true

require 'discordrb/webhooks/embeds'

module Discordrb::Webhooks
  # A class that acts as a builder for a webhook message object.
  class Builder
    def initialize(content: '', username: nil, avatar_url: nil, tts: false, file: nil, embeds: [], allowed_mentions: nil, poll: nil, attachments: [])
      @content = content
      @username = username
      @avatar_url = avatar_url
      @tts = tts
      @file = file
      @embeds = embeds
      @allowed_mentions = allowed_mentions
      @poll = poll
      @attachments = attachments
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

    # Adds an embed to this message.
    # @param embed [Embed] The embed to add.
    def <<(embed)
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

    # Convenience method to add a poll using a builder pattern
    # @example Add a poll to a message
    #   builder.poll(question: "Best Fruit?", duration: 48) do |poll|
    #     poll.answer(text: "Apple", emoji: "🍎")
    #     poll.answer(text: "Orange", emoji: "🍊")
    #     poll.answer(text: "Pomelo", emoji: "🍈")
    #   end
    # @param poll [Poll::Builder, Poll, Hash, nil] The poll to start the building process with, or nil if one should be created anew.
    # @return [Poll::Builder, Poll] The created poll.
    def add_poll(poll = nil, **kwargs)
      poll ||= Discordrb::Poll::Builder.new(**kwargs)
      yield(poll) if block_given?
      @poll = poll
      poll
    end

    alias_method :poll, :add_poll

    # Convinience method to add an attachment.
    # @param file [File] The file or file-like object to upload.
    # @param description [String, nil] The description of the attachment.
    # @param filename [String, nil] The filename to display when viewed on Discord.
    # @param spoiler [true, false, nil] Whether or not to apply a spoiler label to the attachment.
    # @return [void]
    def add_attachment(file, description: nil, filename: nil, spoiler: nil)
      if defined?(StringIO) && file.is_a?(StringIO) && !file.respond_to?(:path)
        raise ArgumentError, "StringIO objects must implement 'path'" unless filename

        file.define_singleton_method(:path) { filename }
      end

      @attachments << { file:, description:, filename:, is_spoiler: spoiler }.compact
    end

    alias_method :add_file, :add_attachment

    # Sets a list of files to be sent together with the message.
    # @param attachments [Array<File>] The files that should be sent.
    def attachments=(attachments)
      attachments = [attachments] unless attachments.is_a?(Array)

      (@attachments = []) && attachments.each { |key| add_attachment(key) }
    end

    alias_method :files=, :attachments=

    # @return [File, nil] the file attached to this message.
    # @deprecated Please migrate to using {#attachments} instead.
    attr_accessor :file

    # @return [Array<Embed>] the embeds attached to this message.
    attr_reader :embeds

    # @return [Discordrb::AllowedMentions, Hash] Mentions that are allowed to ping in this message.
    # @see https://discord.com/developers/docs/resources/channel#allowed-mentions-object
    attr_accessor :allowed_mentions

    # @return [Poll, Poll::Builder, Hash, nil] The poll attached to this message.
    # @see https://discord.com/developers/docs/resources/poll#poll-create-request-object
    attr_writer :poll

    # @return [Hash] a hash representation of the created message, for JSON format.
    def to_json_hash
      {
        content: @content,
        username: @username,
        avatar_url: @avatar_url,
        tts: @tts,
        embeds: @embeds.map(&:to_hash),
        allowed_mentions: @allowed_mentions&.to_hash,
        poll: @poll&.to_h,
        attachments: @attachments.any? ? @attachments : nil
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
        allowed_mentions: @allowed_mentions&.to_hash,
        attachments: @attachments.any? ? @attachments : nil
      }
    end
  end
end
