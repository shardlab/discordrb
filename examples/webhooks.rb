# frozen_string_literal: true

require 'discordrb'
require 'securerandom'

BASE64_SMALL_PICTURE = 'data:image/jpg;base64,iVBORw0KGgoAAAANSUhEUgAAACAAAAAgCAIAAAD8GO2jAAABhGlDQ1BJQ0MgcHJvZmlsZQAAKJF9kT1Iw0AcxV9bpaKtCnYQcchQnSyIijhqFYpQIdQKrTqYXPoFTRqSFBdHwbXg4Mdi1cHFWVcHV0EQ/ABxdHJSdJES/5cUWsR4cNyPd/ced+8Af73MVLNjHFA1y0gl4kImuyoEX9GDfoTRi4DETH1OFJPwHF/38PH1LsazvM/9OcJKzmSATyCeZbphEW8QT29aOud94ggrSgrxOfGYQRckfuS67PIb54LDfp4ZMdKpeeIIsVBoY7mNWdFQiaeIo4qqUb4/47LCeYuzWq6y5j35C0M5bWWZ6zSHkcAiliBCgIwqSijDQoxWjRQTKdqPe/iHHL9ILplcJTByLKACFZLjB/+D392a+ckJNykUBzpfbPtjBAjuAo2abX8f23bjBAg8A1day1+pAzOfpNdaWvQI6NsGLq5bmrwHXO4Ag0+6ZEiOFKDpz+eB9zP6piwwcAt0r7m9Nfdx+gCkqavkDXBwCIwWKHvd491d7b39e6bZ3w/9+3J4GwJBFwAAAAlwSFlzAAAuIwAALiMBeKU/dgAAAAd0SU1FB+YLEA0OHzBTh5kAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAK0lEQVRIx+3NQQEAQAQAMC6DjLKJeSX4bQWW1ROXXhwTCAQCgUAgEAgEWz5KaQFiPn2UJwAAAABJRU5ErkJggg=='
CHANNEL_EDIT = ENV.fetch('CHANNEL_EDIT')

bot = Discordrb::Bot.new(token: ENV.fetch('DISCORDRB_TOKEN'))

bot.message do |event|
  if event.message.content == 'CREATE'
    event.channel.send_message('Create webhook in this channel')

    wh = event.channel.create_webhook('Test', nil, 'Creation webhook')
    wh.execute(content: '[CREATE]')
  end

  if event.message.content == 'EDIT_ONE'
    wh = event.channel.webhooks.first
    wh.update(name: 'Test edited', reason: 'Edition test one')

    puts wh.inspect
    wh.execute(content: '[EDIT ONE]')
  end

  if event.message.content == 'EDIT_TWO'
    wh = event.channel.webhooks.first
    wh.update({ avatar: BASE64_SMALL_PICTURE, reason: 'Edition test two' })

    puts wh.inspect
    wh.execute(content: '[EDIT TWO]')
  end

  if event.message.content == 'EDIT_THREE'
    wh = event.channel.webhooks.first
    wh.update(avatar: nil, channel: event.bot.channel(CHANNEL_EDIT, event.server) || event.channel, reason: 'Edition test three')

    puts wh.inspect
    wh.execute(content: '[EDIT THREE]')
  end

  if event.message.content == 'DELETE'
    wh = (event.bot.channel(CHANNEL_EDIT, event.server) || event.channel).webhooks.first
    wh.delete('Delete webhook')

    puts 'Deleted!'
  end
end

bot.run
