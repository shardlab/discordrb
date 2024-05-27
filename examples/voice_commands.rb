# frozen_string_literal: true

require 'discordrb'
require 'shellwords'

# The `/voice youtube <url>` command assumes that you have yt-dlp installed, and
# available in your path. See: https://github.com/yt-dlp/yt-dlp

bot = Discordrb::Bot.new(
  token: ENV.fetch('SLASH_COMMAND_BOT_TOKEN', nil),
  intents: [:server_messages]
)

bot.register_application_command(:voice, 'Connect and play audio over a voice channel') do |command|
  command.subcommand(:connect, 'Connect to a voice channel')
  command.subcommand(:disconnect, 'Disconnect from a voice channel')
  command.subcommand(:stop, 'Stop playing the current audio')
  command.subcommand(:youtube, 'Play audio from a YouTube video') do |options|
    options.string(:url, 'URL of the youtube video', required: true)
  end
end

bot.application_command(:voice).subcommand(:connect) do |event|
  event.respond(content: 'Connecting...')
  bot.voice_connect(event.user.voice_channel)
  event.edit_response(content: 'Connected!')
end

bot.application_command(:voice).subcommand(:disconnect) do |event|
  voice_channel = bot.voice(event.server.id)&.channel
  if voice_channel
    event.respond(content: 'Disconnecting...')
    voice_channel.destroy
    event.edit_response(content: 'Disconnected!')
  else
    event.respond(content: 'Nothing to do, not connected to voice currently')
  end
end

bot.application_command(:voice).subcommand(:stop) do |event|
  voice_channel = bot.voice(event.server.id)&.channel
  if voice_channel
    event.respond(content: 'Stopping...')
    voice_channel.stop_playing
    event.edit_response(content: 'Stopped!')
  else
    event.respond(content: 'Nothing to do, not connected to voice currently')
  end
end

bot.application_command(:voice).subcommand(:youtube) do |event|
  voice_channel = bot.voice(event.server.id)&.channel
  if voice_channel
    url = command.options['url']
    if valid_youtube_url?(url)
      event.respond(content: 'Playing YouTube video...')
      voice_channel.play_io(youtube_video_io(url))
      event.edit_response(content: 'Finished playing!')
    else
      event.respond(content: 'Invalid YouTube URL'!)
    end
  else
    event.respond(content: 'Please connect to voice with `/voice connect` first')
  end
end

def valid_youtube_url?(url)
  uri = URI(url)
  ['youtu.be', 'youtube.com', 'www.youtube.com'].include?(uri.host)
rescue StandardError
  false
end

def youtube_video_io(url)
  IO.popen("yt-dlp -q -o - #{Shellwords.escape(url)}")
end

bot.run
