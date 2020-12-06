# frozen_string_literal: true

=begin
This was made to show how you can change your bots status with discordrb
I made this because way to many people in the discordrb channel ask how to change the status
=end

# so we make a bot instance here
bot = Discordrb::Commands::CommandBot.new token: '<token-here>', prefix: <prefix-here>

# so this tells the bot that when its ready to do this event
bot.ready do |event|
  event.status.dnd # this can be online idle or dnd
  event.status.playing = "Game" # this can also be watching listeing and more (the docs explain this)
end # this ends the block

at_exit { bot.stop } # tells the bot to stop when the program is done running
bot.run # this runs the  bot
