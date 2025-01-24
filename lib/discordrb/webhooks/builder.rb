# frozen_string_literal: true

require 'discordrb'
require 'discordrb/webhooks/embeds'

module Discordrb::Webhooks
  # A class that acts as a builder for a webhook message object.
  class Builder
    def initialize(content: '', username: nil, avatar_url: nil, tts: false, file: nil, embeds: [], allowed_mentions: nil, attachments: [])
      @content = content
      @username = username
      @avatar_url = avatar_url
      @tts = tts
      @file = file
      @embeds = embeds
      @allowed_mentions = allowed_mentions
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

    # Sets a file to be sent together with the message. Mutually exclusive with embeds; a webhook message can contain
    # either a file to be sent or an embed.
    # @param file [File] A file to be sent.
    # @deprecated Use {#attachments=} instead.
    def file=(file)
      Discordrb::LOGGER.warn('The `file` attribute for the webhook builder is deprecated. Please use `attachments` instead.')
      raise ArgumentError, 'Embeds and files are mutually exclusive!' unless @embeds.empty?

      @file = file
    end

    # Sets files to be sent together with the message. Mutually exclusive with embeds; a webhook message can contain
    # either attachments to be sent or an embed.
    # @param attachments [Array<File>] Files to be sent.
    def attachments=(attachments)
      raise ArgumentError, 'Embeds and attachments are mutually exclusive!' unless @embeds.empty?

      @attachments = attachments
    end

    # Adds an embed to this message.
    # @param embed [Embed] The embed to add.
    def <<(embed)
      raise ArgumentError, 'Embeds and attachments are mutually exclusive!' unless @attachments.empty?

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

    # @return [File, nil] the file attached to this message.
    # @deprecated Use {#attachments} instead.
    attr_reader :file

    # @return [Array<File>] the files attached to this message.
    attr_reader :attachments

    # @return [Array<Embed>] the embeds attached to this message.
    attr_reader :embeds

    # @return [Discordrb::AllowedMentions, Hash] Mentions that are allowed to ping in this message.
    # @see https://discord.com/developers/docs/resources/channel#allowed-mentions-object
    attr_accessor :allowed_mentions

    # @return [Hash] a hash representation of the created message, for JSON format.
    def to_json_hash
      {
        content: @content,
        username: @username,
        avatar_url: @avatar_url,
        tts: @tts,
        embeds: @embeds.map(&:to_hash),
        allowed_mentions: @allowed_mentions&.to_hash
      }
    end

    # @return [Hash] a hash representation of the created message, for multipart format.
    def to_multipart_hash
      hash = {
        content: @content,
        username: @username,
        avatar_url: @avatar_url,
        tts: @tts,
        file: @file, # deprecated
        allowed_mentions: @allowed_mentions&.to_hash
      }

      # if file is specified, prefer old (deprecated) behavior for compatibility
      return hash if file

      hash[:attachments] = @attachments
      hash
    end

    # @return [Hash] a hash representation of the created message, for either json or multipart format depending if a
    # file is present in the builder
    def to_payload_hash
      return to_multipart_hash if !@attachments.empty? || @file

      to_json_hash
    end
  end
end
