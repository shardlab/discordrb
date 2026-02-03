# frozen_string_literal: true

module Discordrb
  # A sound that can be played in voice channels.
  class Sound
    include IDObject

    # @return [String] the name of the soundboard sound.
    attr_reader :name

    # @return [Float] the volume of the soundboaard sound; between 0-1.
    attr_reader :volume

    # @return [true, false] whether or not this soundboard sound is available.
    attr_reader :available
    alias available? available

    # @!visibility private
    def initialize(data, server, bot)
      @bot = bot
      @server = server
      @id = data['sound_id'].to_i
      update_data(data)
    end

    # Get the CDN URL of the soundboard sound.
    # @return [String] The CDN URL of the soundboard sound.
    # @note The returned URL will not have any file extension. Despite
    #   this, the file may be saved in either `mp3` or `ogg` format.
    def url
      API.soundboard_sound_url(@id)
    end

    # Check if the soundboard sound is a default sound.
    # @return [true, false] If the soundboard sound is a default sound.
    def default?
      @server.nil?
    end

    # Get the emoji of the soundboard sound.
    # @return [Emoji, nil] The emoji of the soundboard sound, or `nil`.
    def emoji
      @emoji_id ? @server.emojis[@emoji_id] : @emoji_name
    end

    # Get the user who uploaded the soundboard sound.
    # @return [User, nil] The user who uploaded the soundboard sound, or `nil`.
    def creator
      return @creator if @creator || default?

      update_data(JSON.parse(API::Server.get_soundboard_sound(@bot.token, @server.id, @id)))
      @creator
    end

    # Play the soundboard sound in a voice channel that the bot is currnetly connected to.
    # @param channel [Channel, Integer, String] The channel to play the soundboard sound in.
    # @return [nil]
    def play(channel)
      API::Channel.send_soundboard_sound(@bot.token, channel.resolve_id, @id, @server&.id)
      nil
    end

    # Edit the properties of the soundboard sound.
    # @param name [String] The new 2-32 character name of the soundboard sound.
    # @param emoji [String, Emoji, Integer, nil] The new emoji of the soundboard sound.
    # @param volume [Numeric, nil] The new volume of the soundboard sound, between 0-1.
    # @param reason [String, nil] The reason to show in the audit log for updating the soundboard sound.
    # @raise [Discordrb::Errors::NoPermission] When the bot does not have permission to modify the soundboard sound.
    # @return [nil]
    def modify(name: :undef, emoji: :undef, volume: :undef, reason: nil)
      raise Discordrb::Errors::NoPermission, 'You cannot update a default soundboard sound' if default?

      data = {
        name: name,
        reason: reason,
        volume: volume == :undef ? volume : volume&.to_f,
        **(emoji == :undef ? {} : Emoji.build_emoji_hash(emoji))
      }

      update_data(JSON.parse(API::Server.update_soundboard_sound(@bot.token, @server.id, @id, **data)))
      nil
    end

    # Delete the soundboard sound.
    # @param reason [String, nil] The reason to show in the audit log for deleting the soundboard sound.
    # @raise [Discordrb::Errors::NoPermission] When the bot does not have permission to delete the soundboard sound.
    # @return [nil]
    def delete(reason: nil)
      raise Discordrb::Errors::NoPermission, 'You cannot delete a default soundboard sound' if default?

      API::Server.delete_soundboard_sound(@bot.token, @server.id, @id, reason: reason)
      @server.delete_soundboard_sound(@id)
      nil
    end

    # @!visibility private
    def inspect
      "<Sound id=#{@id} name=\"#{@name}\" volume=#{@volume} available=#{@available} emoji=#{emoji.inspect}>"
    end

    # @!visibility private
    def update_data(new_data)
      @name = new_data['name']
      @volume = new_data['volume']
      @available = new_data['available']
      @emoji_id = new_data['emoji_id']&.to_i
      @creator = @bot.ensure_user(new_data['user']) if new_data['user']
      @emoji_name = new_data['emoji_name'] ? Emoji.new({ 'name' => new_data['emoji_name'] }, @bot) : nil
    end
  end
end
