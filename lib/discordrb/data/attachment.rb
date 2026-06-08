# frozen_string_literal: true

module Discordrb
  # An attachment to a message
  class Attachment
    include IDObject

    # Mapping of attachment flags.
    FLAGS = {
      clip: 1 << 0,
      thumbnail: 1 << 1,
      spoiler: 1 << 3,
      animated: 1 << 5
    }.freeze

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

    # @return [String, nil] the thumbhash of the attachment, if applicable.
    attr_reader :placeholder

    # @return [Integer, nil] the version of the attachment's thumbhash, if applicable.
    attr_reader :placeholder_version

    # @return [Application, nil] the application that was recognized in the clipped stream.
    attr_reader :clip_application

    # @return [Array<User>] the users who were in the clipped stream.
    attr_reader :clip_participants

    # @return [Time, nil] the time at when the clip was created, if applicable.
    attr_reader :clip_creation_time

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

      @placeholder = data['placeholder']
      @placeholder_version = data['placeholder_version']

      @clip_application = Application.new(data['application'], @bot) if data['application']
      @clip_participants = data['clip_participants']&.map { |user| @bot.ensure_user(user) } || []
      @clip_creation_time = Time.iso8601(data['clip_created_at']) if data['clip_created_at']
    end

    # @return [true, false] whether this file is an image file.
    def image?
      !(@width.nil? || @height.nil?)
    end

    # @return [true, false] whether this file is tagged as a spoiler.
    def spoiler?
      @filename.start_with?('SPOILER_') || @flags.anybits?(FLAGS[:spoiler])
    end

    # @return [Message, nil] the message this attachment object belongs to.
    def message
      @message unless @message.is_a?(Snapshot)
    end

    # @return [Snapshot, nil] the message snapshot this attachment object belongs to.
    def snapshot
      @message unless @message.is_a?(Message)
    end

    # @!method clip?
    #   @return [true, false] whether or not the attachment is a clip from a stream.
    # @!method thumbnail?
    #   @return [true, false] whether or not the attachment is the thumbnail of a thread in a media channel.
    # @!method animated?
    #   @return [true, false] whether or not the attachment is considered to be an animated image.
    FLAGS.each do |name, value|
      define_method("#{name}?") { @flags.anybits?(value) } if name != :spoiler
    end
  end
end
