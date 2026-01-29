# frozen_string_literal: true

module Discordrb
  # A forum/media tag that can be applied to threads.
  class ChannelTag
    include IDObject

    # @return [String] the 1-20 character name of the channel tag.
    attr_reader :name

    # @return [Channel] the associated channel of the forum/media tag.
    attr_reader :channel

    # @return [true, false] whether or not the channel tag is moderated.
    attr_reader :moderated
    alias_method :moderated?, :moderated

    # @!visibility private
    def initialize(data, channel, bot)
      @bot = bot
      @channel = channel
      @id = data['id'].to_i
      @name = data['name']
      @moderated = data['moderated']
      @emoji_id = data['emoji_id']&.to_i
      @emoji_name = Emoji.new({ 'name' => data['emoji_name'] }, @bot) if data['emoji_name']
    end

    # Set the name of the channel tag to something new.
    # @param name [String] The new 1-20 character name of the channel tag.
    def name=(name)
      update_data(name: name)
    end

    # Set the emoji of the channel tag to something new.
    # @param emoji [Emoji, Integer, String, nil] The new emoji of the channel tag.
    def emoji=(emoji)
      update_data(Emoji.build_emoji_hash(emoji))
    end

    # Set whether or not the channel tag should be moderated.
    # @param moderated [true, false] Whether or not the channel tag is moderated.
    def moderated=(moderated)
      update_data(moderated: moderated)
    end

    # Permenantly delete the channel tag.
    # @param reason [String, nil] The reason to show in the audit log for deleting the tag.
    def delete(reason: nil)
      @channel.__send__(:update_tags, { id: @id, d: true }, reason)
    end

    # Get the emoji of the channel tag.
    # @return [Emoji, nil] the emoji of this channel tag, or `nil` if no emoji has been set.
    def emoji
      @emoji_id ? @channel.server.emojis[@emoji_id] : @emoji_name
    end

    # @!visibility private
    def to_h
      {
        id: @id,
        name: @name,
        emoji_id: @emoji_id,
        moderated: @moderated,
        emoji_name: @emoji_name&.name
      }
    end

    private

    # @!visibility private
    def update_data(new_data)
      @channel.__send__(:update_tags, to_h.merge(new_data), nil)
    end
  end
end
