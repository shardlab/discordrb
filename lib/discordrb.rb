# frozen_string_literal: true

require 'discordrb/version'
require 'discordrb/bot'
require 'discordrb/commands/command_bot'
require 'discordrb/logger'

# All discordrb functionality, to be extended by other files
module Discordrb
  Thread.current[:discordrb_name] = 'main'

  # The default debug logger used by discordrb.
  LOGGER = Logger.new(ENV['DISCORDRB_FANCY_LOG'])

  # The Unix timestamp Discord IDs are based on
  DISCORD_EPOCH = 1_420_070_400_000

  # Used to declare what events you wish to recieve from Discord.
  # @see https://discord.com/developers/docs/topics/gateway#gateway-intents
  INTENTS = {
    servers: 1 << 0,
    server_members: 1 << 1,
    server_bans: 1 << 2,
    server_emojis: 1 << 3,
    server_integrations: 1 << 4,
    server_webhooks: 1 << 5,
    server_invites: 1 << 6,
    server_voice_states: 1 << 7,
    server_presences: 1 << 8,
    server_messages: 1 << 9,
    server_message_reactions: 1 << 10,
    server_message_typing: 1 << 11,
    direct_messages: 1 << 12,
    direct_message_reactions: 1 << 13,
    direct_message_typing: 1 << 14
  }.freeze

  # All available intents
  ALL_INTENTS = INTENTS.values.reduce(&:|)

  # All unprivileged intents
  # @see https://discord.com/developers/docs/topics/gateway#privileged-intents
  UNPRIVILEGED_INTENTS = ALL_INTENTS & ~(INTENTS[:server_members] | INTENTS[:server_presences])

  # No intents
  NO_INTENTS = 0

  # Compares two objects based on IDs - either the objects' IDs are equal, or one object is equal to the other's ID.
  def self.id_compare(one_id, other)
    other.respond_to?(:resolve_id) ? (one_id.resolve_id == other.resolve_id) : (one_id == other)
  end

  # The maximum length a Discord message can have
  CHARACTER_LIMIT = 2000

  # For creating timestamps with {timestamp}
  # @see https://discord.com/developers/docs/reference#message-formatting-timestamp-styles
  TIMESTAMP_STYLES = {
    short_time: 't', # 16:20
    long_time: 'T', # 16:20:30
    short_date: 'd', # 20/04/2021
    long_date: 'D', # 20 April 2021
    short_datetime: 'f', # 20 April 2021 16:20
    long_datetime: 'F', # Tuesday, 20 April 2021 16:20
    relative: 'R' # 2 months ago
  }.freeze

  # Splits a message into chunks of 2000 characters. Attempts to split by lines if possible.
  # @param msg [String] The message to split.
  # @return [Array<String>] the message split into chunks
  def self.split_message(msg)
    # If the messages is empty, return an empty array
    return [] if msg.empty?

    # Split the message into lines
    lines = msg.lines

    # Turn the message into a "triangle" of consecutively longer slices, for example the array [1,2,3,4] would become
    # [
    #  [1],
    #  [1, 2],
    #  [1, 2, 3],
    #  [1, 2, 3, 4]
    # ]
    tri = (0...lines.length).map { |i| lines.combination(i + 1).first }

    # Join the individual elements together to get an array of strings with consecutively more lines
    joined = tri.map(&:join)

    # Find the largest element that is still below the character limit, or if none such element exists return the first
    ideal = joined.max_by { |e| e.length > CHARACTER_LIMIT ? -1 : e.length }

    # If it's still larger than the character limit (none was smaller than it) split it into the largest chunk without
    # cutting words apart, breaking on the nearest space within character limit, otherwise just return an array with one element
    ideal_ary = ideal.length > CHARACTER_LIMIT ? ideal.split(/(.{1,#{CHARACTER_LIMIT}}\b|.{1,#{CHARACTER_LIMIT}})/o).reject(&:empty?) : [ideal]

    # Slice off the ideal part and strip newlines
    rest = msg[ideal.length..].strip

    # If none remains, return an empty array -> we're done
    return [] unless rest

    # Otherwise, call the method recursively to split the rest of the string and add it onto the ideal array
    ideal_ary + split_message(rest)
  end

  # @param time [Time, Integer] The time to create the timestamp from, or a unix timestamp integer.
  # @param style [Symbol, String] One of the keys from {TIMESTAMP_STYLES} or a string with the style.
  # @return [String]
  # @example
  #   Discordrb.timestamp(Time.now, :short_time)
  #   # => "<t:1632146954:t>"
  def self.timestamp(time, style = nil)
    if style.nil?
      "<t:#{time.to_i}>"
    else
      "<t:#{time.to_i}:#{TIMESTAMP_STYLES[style] || style}>"
    end
  end
end

# In discordrb, Integer and {String} are monkey-patched to allow for easy resolution of IDs
class Integer
  # @return [Integer] The Discord ID represented by this integer, i.e. the integer itself
  def resolve_id
    self
  end
end

# In discordrb, {Integer} and String are monkey-patched to allow for easy resolution of IDs
class String
  # @return [Integer] The Discord ID represented by this string, i.e. the string converted to an integer
  def resolve_id
    to_i
  end
end
