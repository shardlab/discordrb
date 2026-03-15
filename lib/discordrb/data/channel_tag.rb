# frozen_string_literal: true

module Discordrb
  # A forum or media tag that can be applied to threads.
  class ChannelTag
    include IDObject

    # @return [String] the 1-20 character name of the channel tag.
    attr_reader :name

    # @return [Channel] the channel associated with the channel tag.
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

    # Get the emoji of the channel tag.
    # @return [Emoji, nil] the emoji of the channel tag, or `nil` if no emoji has been set.
    def emoji
      @emoji_id ? @channel.server.emojis[@emoji_id] : @emoji_name
    end

    # Modify the properties of the channel tag.
    # @param name [String] The new 1-20 character name of the channel tag.
    # @param emoji [Emoji, Integer, String, nil] The new emoji of the channel tag.
    # @param moderated [true, false] Whether or not the channel tag should be moderated.
    # @param reason [String, nil] The reason to show in the audit log for modifying the tag.
    # @return [nil]
    def modify(name: :undef, emoji: :undef, moderated: :undef, reason: nil)
      data = {
        name: name,
        moderated: moderated,
        **(Emoji.build_emoji_hash(emoji) if emoji != :undef)
      }.reject { |_, value| value == :undef }

      @channel.update_tags(to_h.merge(data), reason)
    end

    # Permenantly delete the channel tag.
    # @param reason [String, nil] The reason to show in the audit log for deleting the tag.
    # @return [nil]
    def delete(reason: nil)
      @channel.update_tags({ id: @id, d: true }, reason)
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
  end
end
