# frozen_string_literal: true

module Discordrb
  # An attachment to a message
  class Attachment
    include IDObject

    # @return [String] the CDN URL this attachment can be downloaded at.
    attr_reader :url

    # @return [String] the attachment's proxy URL - I'm not sure what exactly this does, but I think it has something to
    #   do with CDNs.
    attr_reader :proxy_url

    # @return [String] the attachment's filename.
    attr_reader :filename

    # @return [Integer] the attachment's file size in bytes.
    attr_reader :size

    # @return [Integer, nil] the width of an image file, in pixels, or `nil` if the file is not an image.
    attr_reader :width

    # @return [Integer, nil] the height of an image file, in pixels, or `nil` if the file is not an image.
    attr_reader :height

    # @return [String, nil] the attachment's description.
    attr_reader :description

    # @return [String, nil] the attachment's media type.
    attr_reader :content_type

    # @return [true, false] whether this attachment is ephemeral.
    attr_reader :ephemeral
    alias_method :ephemeral?, :ephemeral

    # @return [Float, nil] the duration of the voice message in seconds.
    attr_reader :duration_seconds

    # @return [String, nil] the base64 encoded bytearray representing a sampled waveform for a voice message.
    attr_reader :waveform

    # @return [Integer] the flags set on this attachment combined as a bitfield.
    attr_reader :flags

    # @!visibility private
    def initialize(data, message, bot)
      @bot = bot
      @message = message

      @id = data['id'].to_i
      @url = data['url']
      @proxy_url = data['proxy_url']
      @filename = data['filename']

      @size = data['size']

      @width = data['width']
      @height = data['height']

      @description = data['description']
      @content_type = data['content_type']

      @ephemeral = data['ephemeral']

      @duration_seconds = data['duration_secs']&.to_f
      @waveform = data['waveform']
      @flags = data['flags'] || 0
    end

    # @return [true, false] whether this file is an image file.
    def image?
      !(@width.nil? || @height.nil?)
    end

    # @return [true, false] whether this file is tagged as a spoiler.
    def spoiler?
      @filename.start_with? 'SPOILER_'
    end

    # @return [Message, nil] the message this attachment object belongs to.
    def message
      @message unless @message.is_a?(Snapshot)
    end

    # @return [Snapshot, nil] the message snapshot this attachment object belongs to.
    def snapshot
      @message unless @message.is_a?(Message)
    end
  end
end
