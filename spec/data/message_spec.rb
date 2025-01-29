# frozen_string_literal: true

require 'discordrb'

describe Discordrb::Message do
  let(:server) { instance_double(Discordrb::Server, 'server') }
  let(:channel) { instance_double(Discordrb::Channel, 'channel', server: server) }
  let(:token) { instance_double(String, 'token') }
  let(:bot) { instance_double(Discordrb::Bot, 'bot', channel: channel, token: token) }
  let(:server_id) { instance_double(String, 'server_id') }
  let(:channel_id) { instance_double(String, 'channel_id') }
  let(:message_id) { instance_double(String, 'message_id') }

  before do
    allow(message_id).to receive_messages(to_i: message_id, to_s: 'message_id')
    allow(server_id).to receive_messages(to_i: server_id, to_s: 'server_id')
    allow(channel_id).to receive_messages(to_i: channel_id, to_s: 'channel_id')

    allow(server).to receive_messages(id: server_id, member: nil)
    allow(channel).to receive_messages(id: channel_id, private?: nil, text?: nil)
    allow(bot).to receive(:server).with(server_id).and_return(server)
    allow(bot).to receive(:channel).with(channel_id).and_return(channel)

    allow(bot).to receive(:ensure_user).with message_author
  end

  fixture :message_data, %i[message]
  fixture_property :message_author, :message_data, ['author']

  describe '#initialize' do
    it 'caches an unavailable author' do
      allow(server).to receive(:member)
      allow(channel).to receive(:private?)
      allow(channel).to receive(:text?)

      # Bot will receive #ensure_user because the observed message author
      # is not present in the server cache, which is possible
      # (for example) if the author had left the server.
      allow(bot).to receive(:ensure_user)
      described_class.new(message_data, bot)
      expect(bot).to have_received(:ensure_user).with message_author
    end
  end

  describe '#emoji' do
    it 'caches and returns only emojis from the message' do
      emoji_a = Discordrb::Emoji.new({ 'name' => 'a', 'id' => 123 }, bot, server)
      emoji_b = Discordrb::Emoji.new({ 'name' => 'b', 'id' => 456 }, bot, server)

      allow(bot).to receive(:user).with('123').and_return(message_author)
      allow(bot).to receive(:channel).with('123', server).and_return(channel)
      allow(bot).to receive(:emoji).with('123').and_return(emoji_a)
      allow(bot).to receive(:emoji).with('456').and_return(emoji_b)
      allow(bot).to receive(:parse_mentions).and_return([message_author, channel, emoji_a, emoji_b])

      data = message_data
      data['id'] = message_id
      data['guild_id'] = server_id
      data['channel_id'] = channel_id

      message = described_class.new(data, bot)
      expect(message.emoji).to eq([emoji_a, emoji_b])
    end

    it 'calls Bot#parse_mentions once' do
      emoji_a = Discordrb::Emoji.new({ 'name' => 'a', 'id' => 123 }, bot, server)
      emoji_b = Discordrb::Emoji.new({ 'name' => 'b', 'id' => 456 }, bot, server)

      allow(bot).to receive(:parse_mentions).once.and_return([emoji_a, emoji_b])

      data = message_data
      data['id'] = message_id
      data['guild_id'] = server_id
      data['channel_id'] = channel_id

      message = described_class.new(data, bot)
      message.emoji
      message.emoji
      expect(bot).to have_received(:parse_mentions).once
    end
  end

  describe '#link' do
    it 'links to a server message' do
      data = message_data
      data['id'] = message_id
      data['guild_id'] = server_id
      data['channel_id'] = channel_id

      message = described_class.new(data, bot)
      expect(message.link).to eq 'https://discord.com/channels/server_id/channel_id/message_id'
    end

    it 'links to a private message' do
      data = message_data
      data['id'] = message_id
      data['guild_id'] = nil
      data['channel_id'] = channel_id

      message = described_class.new(data, bot)
      message.instance_variable_set(:@server, nil)

      expect(message.link).to eq 'https://discord.com/channels/@me/channel_id/message_id'
    end
  end

  describe '#reacted_with' do
    let(:message) { described_class.new(message_data, bot) }
    let(:emoji) { instance_double(Discordrb::Emoji, 'emoji') }
    let(:reaction) { instance_double(Discordrb::Reaction, 'reaction') }

    fixture :user_data, %i[user]

    before do
      allow(Discordrb::API::Channel).to receive(:get_reactions).and_return([].to_json)

      # Return the appropriate number of users based on after_id
      allow(Discordrb::API::Channel).to receive(:get_reactions)
        .with(any_args, nil, anything) # ..., after_id, limit
        .and_return([user_data].to_json)

      allow(Discordrb::API::Channel).to receive(:get_reactions)
        .with(any_args, user_data['id'].to_i, anything)
        .and_return([].to_json)
    end

    it 'calls the API method' do
      message.reacted_with('\u{1F44D}', limit: 27)
      expect(Discordrb::API::Channel).to have_received(:get_reactions)
        .with(any_args, '\u{1F44D}', nil, nil, 27)
    end

    it 'fetches all users when limit is nil' do
      allow(Discordrb::Paginator).to receive(:new).with(nil, :down)

      message.reacted_with('\u{1F44D}', limit: nil)
      expect(Discordrb::Paginator).to have_received(:new).with(nil, :down)
    end

    it 'converts Emoji to strings' do
      string = instance_double(String, 'string')
      allow(emoji).to receive(:to_reaction).and_return(instance_double(Discordrb::Reaction, 'reaction', to_s: string))

      message.reacted_with(emoji)
      expect(Discordrb::API::Channel).to have_received(:get_reactions)
        .with(any_args, string, nil, nil, anything)
    end

    it 'converts Reaction to strings' do
      reaction_string = instance_double(String, 'reaction string')
      allow(reaction).to receive(:to_s).and_return(reaction_string)

      message.reacted_with(reaction)
      expect(Discordrb::API::Channel).to have_received(:get_reactions)
        .with(any_args, reaction_string, nil, nil, anything)
    end
  end

  describe '#all_reaction_users' do
    let(:message) { described_class.new(message_data, bot) }
    let(:reaction_one) { instance_double(Discordrb::Reaction, 'reaction 1') }
    let(:reaction_two) { instance_double(Discordrb::Reaction, 'reaction 2') }
    let(:user_one) { instance_double(Discordrb::User, 'user 1') }
    let(:user_two) { instance_double(Discordrb::User, 'user 2') }
    let(:user_three) { instance_double(Discordrb::User, 'user 3') }

    before do
      message.instance_variable_set(:@reactions, [reaction_one, reaction_two])
      allow(reaction_one).to receive(:to_s).and_return('123')
      allow(reaction_two).to receive(:to_s).and_return('456')

      allow(message).to receive(:reacted_with)
        .with(reaction_one, limit: 100)
        .and_return([user_one, user_two])

      allow(message).to receive(:reacted_with)
        .with(reaction_two, limit: 100)
        .and_return([user_one, user_three])
    end

    it 'returns a filled hash' do
      reactions_hash = message.all_reaction_users
      expect(reactions_hash).to eq({ '123' => [user_one, user_two], '456' => [user_one, user_three] })
    end
  end

  describe '#reply!' do
    let(:message) { described_class.new(message_data, bot) }
    let(:content) { instance_double(String, 'content') }
    let(:mention) { instance_double(TrueClass, 'mention') }

    it 'responds with a message_reference' do
      allow(message).to receive(:respond)
      message.reply!(content)

      expect(message).to have_received(:respond).with(content, false, nil, nil, hash_including(:replied_user), message, nil, 0)
    end

    it 'sets replied_user in allowed_mentions' do
      allow(message).to receive(:respond)
      message.reply!(content, mention_user: mention)

      expect(message).to have_received(:respond).with(content, false, nil, nil, { replied_user: mention }, message, nil, 0)
    end

    context 'when allowed_mentions is false' do
      let(:mention) { instance_double(TrueClass, 'mention') }

      it 'sets parse to an empty array add merges the mention_user param' do
        allow(message).to receive(:respond)
        message.reply!(content, allowed_mentions: false, mention_user: mention, flags: 0)

        expect(message).to have_received(:respond).with(content, false, nil, nil, { parse: [], replied_user: mention }, message, nil, 0)
      end
    end

    context 'when allowed_mentions is an AllowedMentions' do
      let(:hash) { instance_double(Hash, 'hash') }
      let(:allowed_mentions) { instance_double(Discordrb::AllowedMentions, 'allowed_mentions') }
      let(:mention_user) { instance_double(TrueClass, 'mention_user') }

      before do
        allow(allowed_mentions).to receive(:to_hash).and_return(hash)
        allow(hash).to receive(:transform_keys).with(any_args).and_return(hash)
        allow(hash).to receive(:[]=).with(:replied_user, mention_user)
      end

      it 'converts it to a hash to set the replied_user key' do
        allow(message).to receive(:respond)
        message.reply!(content, allowed_mentions: allowed_mentions, mention_user: mention_user, flags: 0)
        expect(message).to have_received(:respond).with(content, false, nil, nil, hash, message, nil, 0)
      end
    end
  end

  describe '#reply' do
    let(:message) { described_class.new(message_data, bot) }
    let(:content) { instance_double(String, 'content') }

    it 'sends a message to a channel' do
      allow(channel).to receive(:send_message)
      message.reply(content)

      expect(channel).to have_received(:send_message).with(content)
    end
  end

  describe '#respond' do
    let(:message) { described_class.new(message_data, bot) }
    let(:content) { instance_double(String, 'content') }
    let(:tts) { instance_double(TrueClass, 'tts') }
    let(:embed) { instance_double(Discordrb::Webhooks::Embed, 'embed') }
    let(:attachments) { instance_double(Array, 'attachments') }
    let(:allowed_mentions) { instance_double(Hash, 'allowed_mentions') }
    let(:message_reference) { instance_double(described_class) }
    let(:components) { instance_double(Discordrb::Webhooks::View) }

    it 'forwards arguments to Channel#send_message' do
      flags = instance_double(Integer)
      allow(channel).to receive(:send_message)
      message.respond(content, tts, embed, attachments, allowed_mentions, message_reference, components, flags)

      expect(channel).to have_received(:send_message).with(content, tts, embed, attachments, allowed_mentions, message_reference, components, flags)
    end
  end
end
