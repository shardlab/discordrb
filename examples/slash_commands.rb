# frozen_string_literal: true

require 'discordrb'

bot = Discordrb::Bot.new(token: ENV['SLASH_COMMAND_BOT_TOKEN'])

# We need to register our application comomands separately from the handlers with a special DSL.
# This example uses server specifc commands so that they appear immediately for testing,
# but you can omit the server_id as well to register a global command that can take up to an hour
# to appear.
#
# You may want to have a separate script for registering your commands so you don't need to do this every
# time you start your bot.
bot.register_application_command(:example, 'Example commands', server_id: ENV['SLASH_COMMAND_BOT_SERVER_ID']) do |cmd|
  cmd.subcommand_group(:fun, 'Fun things!') do |group|
    group.subcommand('8ball', 'Shake the magic 8 ball') do |sub|
      sub.string('question', 'Ask a question to receive wisdom', required: true)
    end

    group.subcommand('java', 'What if it was java?')

    group.subcommand('calculator', 'do math!') do |sub|
      sub.integer('first', 'First number')
      sub.string('operation', 'What to do', choices: { times: '*', divided_by: '/', plus: '+', minus: '-' })
      sub.integer('second', 'Second number')
    end
  end
end

bot.register_application_command(:spongecase, 'Are you mocking me?', server_id: ENV['SLASH_COMMAND_BOT_SERVER_ID']) do |cmd|
  cmd.string('message', 'Message to spongecase')
  cmd.boolean('with_picture', 'Show the mocking sponge?')
end

# This is a really large and fairly pointless example of a subcommand.
# You can also create subcommand handlers directly on the command like so
#    bot.application_command(:other_example).subcommand(:test) do |event|
#      # ...
#    end
#    bot.application_command(:other_example).subcommand(:test2) do |event|
#      # ...
#    end
bot.application_command(:example).group(:fun) do |group|
  group.subcommand('8ball') do |event|
    wisdom = ['Yes', 'No', 'Try Again Later'].sample
    event.respond(content: <<~STR, ephemeral: true)
      ```
      #{event.options['question']}
      ```
      _#{wisdom}_
    STR
  end

  group.subcommand(:java) do |event|
    javaisms = %w[Factory Builder Service Provider Instance Class Reducer Map]
    jumble = []
    [*5..10].sample.times do
      jumble << javaisms.sample
    end

    event.respond(content: jumble.join)
  end

  group.subcommand(:calculator) do |event|
    result = event.options['first'].send(event.options['operation'], event.options['second'])
    event.respond(content: result)
  end
end

bot.application_command(:spongecase) do |event|
  ops = %i[upcase downcase]
  text = event.options['message'].chars.map { |x| x.__send__(ops.sample) }.join
  event.respond(content: text)

  event.send_message(content: 'https://pyxis.nymag.com/v1/imgs/09c/923/65324bb3906b6865f904a72f8f8a908541-16-spongebob-explainer.rsquare.w700.jpg') if event.options['with_picture']
end

bot.run
