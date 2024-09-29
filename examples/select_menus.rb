# frozen_string_literal: true

require 'discordrb'
require 'securerandom'

bot = Discordrb::Bot.new(token: ENV.fetch('DISCORDRB_TOKEN'))

bot.message do |event|
  if event.message.content == 'TEST'
    event.channel.send_message('Examples of different select menus')

    event.channel.send_message(
      'string_select (old select_menu, but alias define to keep legacy)', false, nil, nil, nil, nil,
      Discordrb::Components::View.new do |builder|
        builder.row do |r|
          r.string_select(custom_id: 'string_select', placeholder: 'Test of StringSelect', max_values: 3) do |ss|
            ss.option(label: 'Value 1', value: '1', description: 'First value', emoji: { name: '1️⃣' })
            ss.option(label: 'Value 2', value: '2', description: 'Second value', emoji: { name: '2️⃣' })
            ss.option(label: 'Value 3', value: '3', description: 'Third value', emoji: { name: '3️⃣' })
          end
          # Same as above with the alias to keep the compatibility with the old method
          # r.select_menu(custom_id: 'string_select', placeholder: 'Test of StringSelect', max_values: 3) do |ss|
          #   ss.option(label: 'Value 1', value: '1', description: 'First value', emoji: { name: '1️⃣' })
          #   ss.option(label: 'Value 2', value: '2', description: 'Second value', emoji: { name: '2️⃣' })
          #   ss.option(label: 'Value 3', value: '3', description: 'Third value', emoji: { name: '3️⃣' })
          # end
        end
      end
    )

    event.channel.send_message(
      'user_select', false, nil, nil, nil, nil,
      Discordrb::Components::View.new do |builder|
        builder.row do |r|
          r.user_select(custom_id: 'user_select', placeholder: 'Test of UserSelect', max_values: 3, disabled: true)
        end
      end
    )

    event.channel.send_message(
      'user_select', false, nil, nil, nil, nil,
      Discordrb::Components::View.new do |builder|
        builder.row do |r|
          r.user_select(custom_id: 'user_select', placeholder: 'Test of UserSelect', max_values: 3)
        end
      end
    )

    event.channel.send_message(
      'role_select', false, nil, nil, nil, nil,
      Discordrb::Components::View.new do |builder|
        builder.row do |r|
          r.role_select(custom_id: 'role_select', placeholder: 'Test of RoleSelect', max_values: 3)
        end
      end
    )

    event.channel.send_message(
      'mentionable_select', false, nil, nil, nil, nil,
      Discordrb::Components::View.new do |builder|
        builder.row do |r|
          r.mentionable_select(custom_id: 'mentionable_select', placeholder: 'Test of MentionableSelect', max_values: 3)
        end
      end
    )

    event.channel.send_message(
      'channel_select', false, nil, nil, nil, nil,
      Discordrb::Components::View.new do |builder|
        builder.row do |r|
          r.channel_select(custom_id: 'channel_select', placeholder: 'Test of ChannelSelect', max_values: 3)
        end
      end
    )
  end
end

bot.string_select do |event|
  # bot.select_menu do |event| # also available with the alias to keep the compatibility with the old method
  event.interaction.respond(
    content: "**[STRING_SELECT]**\nYou have chosen the values: **#{event.values.join('**, **')}**",
    ephemeral: true
  )
end

bot.user_select do |event|
  event.interaction.respond(
    content: "**[USER_SELECT]**\nYou have chosen users : **#{event.values.map(&:username).join('**, **')}**",
    ephemeral: true
  )
end

bot.role_select do |event|
  event.interaction.respond(
    content: "**[ROLE_SELECT]**\nYou have chosen roles : **#{event.values.map(&:name).join('**, **')}**",
    ephemeral: true
  )
end

bot.mentionable_select do |event|
  event.interaction.respond(
    content: "**[MENTIONABLE_SELECT]**\nYou have chosen mentionables :\n  Users: **#{event.values[:users].map(&:username).join('**, **')}**\n  Roles: **#{event.values[:roles].map(&:name).join('**, **')}**",
    ephemeral: true
  )
end

bot.channel_select do |event|
  event.interaction.respond(
    content: "**[CHANNEL_SELECT]**\nYou have chosen channels : **#{event.values.map(&:name).join('**, **')}**",
    ephemeral: true
  )
end

bot.run
