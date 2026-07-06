# frozen_string_literal: true

module Discordrb
  # A sound that can be played in voice channels.
  class SoundboardSound
    include IDObject

    # @return [String] the name of the soundboard sound.
    attr_reader :name

    # @return [Server, nil] the server of the soundboard sound.
    attr_reader :server

    # @return [Float] the volume of the soundboard sound; between 0-1.
    attr_reader :volume

    # @return [true, false] whether or not the soundboard sound can be used.
    attr_reader :available
    alias available? available

    # @!visibility private
    def initialize(data, server, bot)
      @bot = bot
      @server = server
      @id = data['sound_id'].to_i
      update_data(data)
    end

    # The CDN URL of the soundboard sound.
    # @return [String] The CDN URL of the soundbord sound.
    # @note You can save the URL to a file in `.mp3` or `.ogg` format.
    def url
      API.soundboard_sound_url(@id)
    end

    # Get the emoji of the soundboard sound.
    # @return [Emoji, nil] The emoji of the soundboard sound, or `nil`.
    def emoji
      @emoji_id ? @server.emojis[@emoji_id] : @emoji_name
    end

    # Get the creator of the soundboard sound.
    # @return [User, nil] The user who created the soundboard sound, or `nil`.
    def creator
      return @creator unless @creator.nil? && !@server.nil?

      return unless @server.bot.can_manage_emojis? || @server.bot.can_create_expressions?

      update_data(JSON.parse(API::Server.get_soundboard_sound(@bot.token, @server.id, @id)))

      @creator
    end

    # Delete the soundboard sound.
    # @param reason [String, nil] The reason to show in the audit log for deleting the soundboard sound.
    # @return [nil]
    def delete(reason: nil)
      API::Server.delete_soundboard_sound(@bot.token, @server.id, @id, reason: reason)
      nil.tap { @server.delete_soundboard_sound(@id) }
    end

    # Play the soundboard sound in a voice channel.
    # @param channel [Channel, Integer, String] The channel where the soundboard sound should be played.
    # @return [nil]
    def play(channel)
      API::Channel.send_soundboard_sound(@bot.token, channel.resolve_id, @id, @server&.id)
      nil
    end

    # Modify the properties of the soundboard sound.
    # @param name [String] The new name of the soundboard sound; between 2-32 characters.
    # @param volume [Float, #to_f, nil] The new volume of the soundboard sound; between 0-1.
    # @param emoji [Emoji, Integer, String, Reaction, nil] The new emoji of the soundboard sound.
    # @param reason [String, nil] The reason to show in the audit log for modifying the soundboard sound.
    # @return [nil]
    def modify(name: :undef, volume: :undef, emoji: :undef, reason: nil)
      data = {
        name: name,
        reason: reason,
        volume: volume == :undef ? volume : volume&.to_f,
        **(emoji == :undef ? {} : Emoji.build_emoji_hash(emoji))
      }

      update_data(JSON.parse(API::Server.update_soundboard_sound(@bot.token, @server.id, @id, **data)))
      nil
    end

    # @!visibility private
    def inspect
      "<SoundboardSound id=#{@id} name=\"#{@name}\" volume=#{@volume} available=#{@available.inspect}>"
    end

    # @!visibility private
    def update_data(new_data)
      @name = new_data['name']
      @volume = new_data['volume'].to_f
      @available = new_data['available']
      @emoji_id = new_data['emoji_id']&.to_i
      @creator = @bot.ensure_user(new_data['user']) if new_data['user']
      @emoji_name = new_data['emoji_name'] ? Emoji.new({ 'name' => new_data['emoji_name'] }, @bot) : nil
    end
  end
end
