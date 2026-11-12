# frozen_string_literal: true

# This simple bot implements a custom logger.

require 'discordrb'

# A custom logger can be any object that responds to #flush and #puts
# like a {File}. In our case, we're using a singleton class, where we've
# implemented these methods ourselves, but you're free to use any kind of
# object that meets the requirements above.
#
# Our logger collects messages that Discordrb sends to us and then buffers
# those messages in-memory, before finally flushing them to a file on disk.
# For the sake of simplicity, we're going to use a background-thread to do this.
class CustomLogger
  LOGGER_MESSAGES = [] # rubocop:disable Style/MutableConstant

  WORKER_THREAD = Thread.new do
    loop do
      sleep(60 * 5)

      messages = LOGGER_MESSAGES.shift(1000)

      # Wait five more minutes and then check again.
      next if messages.empty?

      File.write('logs.txt', "#{messages.join("\n")}\n", mode: 'ab')
    end
  end

  # Usually, "flushing" would refer to writing your data to its
  # source instead of waiting for some sort of buffer to fill up.
  # Since #flush is called by Discordrb every time the logger is
  # invoked, we actually don't want this method to do anything.
  def self.flush; end

  # This is called every time Discordrb has a message for us. Here, `input` is a string such as:
  # "[INFO : websocket @ 2026-10-03 09:02:33.972] Discord using gateway protocol version: 9, requested: 9"
  def self.puts(input)
    LOGGER_MESSAGES << input
  end
end

# Tells Discordrb to write logs to our custom class.
# You can have multiple streams, meaning that you could print to the console as well, but for
# the sake of the example, we'll only use a single stream.
Discordrb::LOGGER.streams = [CustomLogger]

bot = Discordrb::Bot.new(token: ENV.fetch('BOT_TOKEN'), log_mode: :verbose, intents: [:guilds])

bot.run
