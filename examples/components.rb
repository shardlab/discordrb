# frozen_string_literal: true

require 'discordrb'

bot = Discordrb::Bot.new(token: ENV.fetch('BOT_TOKEN', nil), intents: %i[servers server_emojis server_messages])

bot.register_application_command(:components, 'Components version two!', server_id: ENV.fetch('SERVER_ID', nil)) do |option|
  option.boolean('color', 'Whether the container should include an accent color.', required: false)
end

bot.application_command(:components) do |event|
  # Map the first 15 emojis from the server our command is
  # called from into the formart of: "mention - name **{Integer}**".
  emojis = event.server.emojis.values.take(15).map do |emoji|
    "#{emoji.mention} — #{emoji.name} **(#{rand(1..500)})**\n"
  end

  # The `has_components` argument must be manually set to true
  # to use V2 components. Doing so disables sending content and embeds.
  event.respond(has_components: true) do |_, view|
    # A new container is added to contain other components.
    # We don't have to do this, since all components besides buttons
    # and select menus can be used as top level components.
    view.container(id: 100) do |container|
      # A section must have either a thumbnail or a button. This is currently
      # the only case where a button can be used without being in an action row.
      container.section do |section|
        section.thumbnail(url: event.server.icon_url)
        section.text_display(text: "### Emoji Statistics for #{event.server.name}")
        section.text_display(text: 'These are the fake emoji statistics for your server.')
      end

      # If set to true, the accent color is set to the user's current
      # color, otherwise the container won't have an accent color.
      container.color = event.user.color if event.options['color']

      # A seperator can appear as a thin, translucent, grey
      # line when setting the divider option to true. Otherwise
      # the seperator can function as an invisible barrier to proivde
      # spacing between other components.
      container.seperator(divider: true, spacing: :small)

      # A text display container is a container for text. Like with the content field,
      # you can use markdown, emoji, allowed_mentions, etc.
      container.text_display(text: emojis.empty? ? 'No Emojis!' : emojis.join)

      # Try setting the spacing to `:large` to have a bigger gap between the other components.
      container.seperator(divider: true, spacing: :small)

      # We clear the existing emojis array and add a random emoji to the emojis array.
      emojis.clear && 3.times { emojis << event.server.emojis.values.sample }

      # We can add a select menu inside of our containter as shown here. Buttons
      # can be added as well, although selects and buttons still have to be nested
      # within an action row. but this can change in the future.
      container.row do |row|
        row.select_menu(custom_id: 'emojis', placeholder: 'Pick a statistic type...', min_values: 1) do |menu|
          menu.option(label: 'Reaction', value: 'Reaction', description: 'View reaction statistics.', emoji: emojis.pop)
          menu.option(label: 'Message', value: 'Message', description: 'View message statistics.', emoji: emojis.pop)
          menu.option(label: 'Lowest', value: 'Lowest', description: 'View the boring emojis.', emoji: emojis.pop)
        end
      end
    end
  end
end

# This doesn't actually display any stats, but returns a placeholder message instead.
bot.select_menu(custom_id: 'emojis') do |event|
  case event.values.first
  when 'Reaction', 'Message'
    event.respond(content: "You're viewing stats for #{event.values.first}s!", ephemeral: true)
  when 'Lowest'
    event.respond(content: "You're viewing very boring stats!", ephemeral: true)
  else
    event.respond(content: 'What kind of stats...', ephemeral: true)
  end
end

# The second example is a little more generic and uses a standard message sent to a channel.
bot.message(content: '!sample') do |event|
  # Any of the components used below can be used within a container as well.
  event.send_message!(has_components: true) do |_, view|
    view.text_display(text: <<~CONTENT)
      This is a text display component! Any markdown that can be used in the `content` field can also be used here.\n
      ~~strikethrough~~ **bold text** *italics* ||spoiler|| `code` __underline__ [masked link](https://youtu.be/dQw4w9WgXcQ)\n
      ```ruby
      puts("Hello World!")
      ```
    CONTENT

    # Just like in the example above, we can set `:divider` to true in order to generate a barrier.
    view.seperator(divider: true, spacing: :large)

    # A media gallery is a container for multiple pieces of media, such as videos, GIFs or staic images.
    # You can add optionally add alt text via the `description:` argument and spoiler each media item.
    view.media_gallery do |gallery|
      gallery.item(url: 'https://static.wikitide.net/sillycatsbookwiki/f/f7/Apple_Cat.jpg', description: 'Greedy Cat')
      gallery.item(url: 'https://media.tenor.com/FkXcRz7-9PwAAAAd/oh-boy-patrick.gif', spoiler: true)
    end

    # A Section allows you to group together text display components and pair them with an accessory.
    # In the emoji stats example above, we had a section with a  thumbnail component. At the time of writing,
    # a section must container either a thumbnail **or** a button, but not both at the same time.
    view.section(id: rand(100..600)) do |section|
      section.text_display(text: 'This is text from a section. This section has a button instead of a thumbnail.')

      section.button(label: 'Delete', style: :danger, custom_id: 'delete_message', emoji: 577658883468689409)
    end
  end
end

# Delete the message that was sent in response to "!sample".
bot.button(custom_id: 'delete_message') do |event|
  event.respond(content: 'Successfully deleted the message.', ephemeral: true)

  event.message.delete
end

bot.run
