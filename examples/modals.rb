# frozen_string_literal: true

require 'discordrb'
require 'securerandom'

bot = Discordrb::Bot.new(token: ENV.fetch('DISCORDRB_TOKEN'))
bot.register_application_command(:modal_test, 'Test out a spiffy modal', server_id: ENV.fetch('DISCORDRB_SERVER_ID'))
bot.register_application_command(:modal_await_test, 'Test out the await style', server_id: ENV.fetch('DISCORDRB_SERVER_ID'))

bot.application_command :modal_test do |event|
  event.show_modal(title: 'Test modal', custom_id: 'test1234') do |modal|
    modal.row do |row|
      row.text_input(
        style: :paragraph,
        custom_id: 'input',
        label: 'Test input',
        required: true,
        placeholder: 'Type something to submit.'
      )
    end
  end
end

bot.application_command :modal_await_test do |event|
  id = SecureRandom.uuid
  event.show_modal(title: "I'm waiting for you", custom_id: id) do |modal|
    modal.row do |row|
      row.text_input(
        style: :paragraph,
        custom_id: 'input',
        label: 'Test input',
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
  event.respond(content: "Thanks for submitting your modal. You sent #{event.value('input').chars.count} characters.")
end

bot.run
