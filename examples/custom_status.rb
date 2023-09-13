# frozen_string_literal: true

require 'discordrb'

bot = Discordrb::Bot.new token: ENV.fetch('DISCORDRB_TOKEN')
custom_status = ['Hello World!', '❤️ Love you', 'Finally custom status 🎉']
initialized = false
thread = []

bot.ready do |_|
  next if initialized

  bot.game = 'game'
  sleep 5

  bot.listening = 'music'
  sleep 5

  bot.watching = 'you'
  sleep 5

  bot.competing = 'mario kart'
  sleep 5

  bot.stream('discordrb', 'https://twitch.tv/shardlab')
  sleep 5

  initialized = true
  thread << Thread.new do
    loop do
      bot.custom_status = custom_status.first
      custom_status.rotate!

      sleep 5
    end
  end
end

at_exit do
  thread.each(&:exit)
  bot.stop
end

bot.run
