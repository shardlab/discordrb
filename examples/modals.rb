# frozen_string_literal: true

require 'discordrb'
require 'securerandom'

bot = Discordrb::Bot.new(token: ENV.fetch('DISCORDRB_TOKEN'))
bot.register_application_command(:modal_test, 'Test out a spiffy modal', server_id: ENV.fetch('DISCORDRB_SERVER_ID'))
bot.register_application_command(:modal_await_test, 'Test out the await style', server_id: ENV.fetch('DISCORDRB_SERVER_ID'))

bot.application_command :modal_test do |event|
  event.show_modal(title: 'Test modal', custom_id: 'test1234') do |modal|
    modal.label(label: 'Test input') do |label|
      label.text_input(
        style: :paragraph,
        custom_id: 'input',
        required: true,
        placeholder: 'Type something to submit.'
      )
    end

    # We can add a select menu inside of a modal as well.
    modal.label(label: 'Fruit Picker') do |label|
      label.string_select(custom_id: 'fruits', placeholder: 'Pick a fruit...', max_values: 3, required: false) do |menu|
        menu.option(label: 'Banana', value: 'banana', description: 'A yellow pulpy curved fruit.', emoji: '🍌')
        menu.option(label: 'Peach', value: 'peach', description: 'A soft orange-ish fuzzy fruit.', emoji: '🍑')
        menu.option(label: 'Pear', value: 'pear', description: 'A green fruit with gritty pulp.', emoji: '🍐')
      end
    end

    # Text displays are allowed to be used as a top level component.
    modal.text_display(text: <<~CONTENT)
      This is a text display component in a modal! This is the same as a normal text display component.\n
      ~~strikethrough~~ **bold text** *italics* ||spoiler|| `code` __underline__ [masked link](https://youtu.be/dQw4w9WgXcQ)\n
      ```ruby
      puts("Hello Modal!")
      ```
    CONTENT

    modal.label(label: 'Channel Picker', description: 'This is an optional description for a label component.') do |label|
      label.channel_select(custom_id: 'channels', placeholder: 'Pick a channel...', required: true, max_values: 7, types: %i[text news])
    end
  end
end

bot.application_command :modal_await_test do |event|
  id = SecureRandom.uuid
  event.show_modal(title: "I'm waiting for you", custom_id: id) do |modal|
    modal.label(label: 'Test input') do |label|
      label.text_input(
        style: :paragraph,
        custom_id: 'input',
        required: true,
        placeholder: 'Type something to submit.'
      )
    end
  end

  start_time = Time.now
  modal_event = bot.add_await!(Discordrb::Events::ModalSubmitEvent, custom_id: id, timeout: (60 * 10))

  if event.nil?
    modal_event.respond(content: "Time's up!", ephemeral: true)
  else
    modal_event.respond(content: "Thanks for submitting your modal. I waited #{Time.now - start_time} seconds")
  end
end

bot.modal_submit custom_id: 'test1234' do |event|
  # The selected values for the string select can be accessed via {#values}.
  select_response = "and picked #{event.values('fruits')&.size} fruits."

  event.respond(content: "Thanks for submitting your modal. You sent #{event.value('input').chars.count} characters, #{select_response}")
end

bot.run
