# frozen_string_literal: true

require 'discordrb'

describe Discordrb::Events do
  describe Discordrb::Events::Negated do
    it 'initializes without errors' do
      expect { described_class.new(:test) }.not_to raise_error
    end

    it 'contains the passed object' do
      negated = described_class.new(:test)
      expect(negated.object).to eq :test
    end
  end

  describe 'not!' do
    it 'returns a Negated object' do
      expect(not!(:test)).to be_a(described_class::Negated)
    end

    it 'contains the correct value' do
      expect(not!(:test).object).to be :test
    end
  end

  describe '.matches_all' do
    it 'returns true for a nil attribute' do
      expect(described_class.matches_all(nil, nil)).to be true
    end

    # TODO: Rework tests to not rely on multiple expectations
    # rubocop:disable RSpec/MultipleExpectations
    it 'is truthy if the block is truthy' do
      expect(described_class.matches_all(:a, :e) { true }).to be_truthy
      expect(described_class.matches_all(:a, :e) { 1 }).to be_truthy
      expect(described_class.matches_all(:a, :e) { 0 }).to be_truthy
      expect(described_class.matches_all(:a, :e) { 'string' }).to be_truthy
      expect(described_class.matches_all(:a, :e) { false }).not_to be_truthy
    end

    it 'is falsey if the block is falsey' do
      expect(described_class.matches_all(:a, :e) { nil }).to be_falsy
      expect(described_class.matches_all(:a, :e) { false }).to be_falsy
      expect(described_class.matches_all(:a, :e) { 0 }).not_to be_falsy
    end

    it 'correctly passes the arguments given' do
      described_class.matches_all(:one, :two) do |a, e|
        expect(a).to be :one
        expect(e).to be :two
      end
    end

    it 'correctly compares arguments for comparison blocks' do
      expect(described_class.matches_all(1, 1) { |a, e| a == e }).to be_truthy
      expect(described_class.matches_all(1, 0) { |a, e| a == e }).to be_falsy
      expect(described_class.matches_all(0, 1) { |a, e| a == e }).to be_falsy
      expect(described_class.matches_all(0, 0) { |a, e| a == e }).to be_truthy
      expect(described_class.matches_all(1, 1) { |a, e| a != e }).to be_falsy
      expect(described_class.matches_all(1, 0) { |a, e| a != e }).to be_truthy
      expect(described_class.matches_all(0, 1) { |a, e| a != e }).to be_truthy
      expect(described_class.matches_all(0, 0) { |a, e| a != e }).to be_falsy
    end

    it 'returns the opposite results for negated arguments' do
      expect(described_class.matches_all(not!(:a), :e) { true }).to be_falsy
      expect(described_class.matches_all(not!(:a), :e) { 1 }).to be_falsy
      expect(described_class.matches_all(not!(:a), :e) { 0 }).to be_falsy
      expect(described_class.matches_all(not!(:a), :e) { 'string' }).to be_falsy
      expect(described_class.matches_all(not!(:a), :e) { false }).not_to be_falsy
      expect(described_class.matches_all(not!(:a), :e) { nil }).to be_truthy
      expect(described_class.matches_all(not!(:a), :e) { false }).to be_truthy
      expect(described_class.matches_all(not!(:a), :e) { 0 }).not_to be_truthy
      expect(described_class.matches_all(not!(1), 1) { |a, e| a == e }).to be_falsy
      expect(described_class.matches_all(not!(1), 0) { |a, e| a == e }).to be_truthy
      expect(described_class.matches_all(not!(0), 1) { |a, e| a == e }).to be_truthy
      expect(described_class.matches_all(not!(0), 0) { |a, e| a == e }).to be_falsy
      expect(described_class.matches_all(not!(1), 1) { |a, e| a != e }).to be_truthy
      expect(described_class.matches_all(not!(1), 0) { |a, e| a != e }).to be_falsy
      expect(described_class.matches_all(not!(0), 1) { |a, e| a != e }).to be_falsy
      expect(described_class.matches_all(not!(0), 0) { |a, e| a != e }).to be_truthy
    end

    it 'finds one correct element inside arrays' do
      expect(described_class.matches_all([1, 2, 3], 1) { |a, e| a == e }).to be_truthy
      expect(described_class.matches_all([1, 2, 3], 2) { |a, e| a == e }).to be_truthy
      expect(described_class.matches_all([1, 2, 3], 3) { |a, e| a == e }).to be_truthy
      expect(described_class.matches_all([1, 2, 3], 4) { |a, e| a != e }).to be_truthy
    end

    it 'returns false when nothing matches inside arrays' do
      expect(described_class.matches_all([1, 2, 3], 4) { |a, e| a == e }).to be_falsy
    end

    it 'returns the respective opposite results for negated arrays' do
      expect(described_class.matches_all(not!([1, 2, 3]), 1) { |a, e| a == e }).to be_falsy
      expect(described_class.matches_all(not!([1, 2, 3]), 2) { |a, e| a == e }).to be_falsy
      expect(described_class.matches_all(not!([1, 2, 3]), 3) { |a, e| a == e }).to be_falsy
      expect(described_class.matches_all(not!([1, 2, 3]), 4) { |a, e| a != e }).to be_falsy
      expect(described_class.matches_all(not!([1, 2, 3]), 4) { |a, e| a == e }).to be_truthy
    end
    # rubocop:enable RSpec/MultipleExpectations
  end

  describe Discordrb::Events::MessageEvent do
    subject :event do
      described_class.new(message, bot)
    end

    let(:bot) { double }
    let(:channel) { double }
    let(:message) { instance_double(Discordrb::Message, 'message', channel: channel) }

    describe 'after_call' do
      subject :handler do
        Discordrb::Events::MessageEventHandler.new(double, double)
      end

      it 'calls send_file with attached file, filename, and spoiler' do
        file = double
        filename = double
        spoiler = double
        allow(file).to receive(:is_a?).with(File).and_return(true)
        allow(event).to receive(:send_file)

        event.attach_file(file, filename: filename, spoiler: spoiler)
        handler.after_call(event)
        expect(event).to have_received(:send_file).with(file, caption: '', filename: filename, spoiler: spoiler)
      end
    end
  end

  describe Discordrb::Events::EventHandler do
    describe 'matches?' do
      it 'raises an error' do
        expect { described_class.new({}, nil).matches?(nil) }.to raise_error(RuntimeError)
      end
    end
  end

  describe Discordrb::Events::TrueEventHandler do
    describe 'matches?' do
      it 'returns true' do
        expect(described_class.new({}, nil).matches?(nil)).to be true
      end

      it 'always calls the block given' do
        count = 0
        described_class.new({}, proc { count += 1 }).match(nil)
        described_class.new({}, proc { count += 2 }).match(1)
        described_class.new({}, proc do |e|
          expect(e).to eq(1)
          count += 4
        end).match(1)
        described_class.new({ a: :b }, proc { count += 8 }).match(1)
        described_class.new(nil, proc { count += 16 }).match(1)
      end
    end
  end

  describe Discordrb::Events::MessageEventHandler do
    describe 'matches?' do
      it 'calls with empty attributes', skip: 'meew0 disabled in 2cf0a42' do
        t = track('empty attributes')
        event = double
        described_class.new({}, proc { t.track(1) }).match(event)
        t.summary
      end
    end

    shared_examples 'end_with attributes' do |expr, matching, non_matching|
      describe 'end_with attribute' do
        it "matches #{matching}" do
          handler = described_class.new({ end_with: expr }, double)
          event = instance_double(Discordrb::Events::MessageEvent, 'event', channel: instance_double(Discordrb::Channel, 'channel', private?: false), author: double, timestamp: double, content: matching)
          allow(event).to receive(:is_a?).with(Discordrb::Events::MessageEvent).and_return(true)
          expect(handler).to be_matching(event)
        end

        it "doesn't match #{non_matching}" do
          handler = described_class.new({ end_with: expr }, double)
          event = instance_double(Discordrb::Events::MessageEvent, 'event', channel: instance_double(Discordrb::Channel, 'channel', private?: false), author: double, timestamp: double, content: non_matching)
          allow(event).to receive(:is_a?).with(Discordrb::Events::MessageEvent).and_return(true)
          expect(handler).not_to be_matching(event)
        end
      end
    end

    include_examples(
      'end_with attributes', /foo/, 'foo', 'f'
    )

    include_examples(
      'end_with attributes', /!$/, 'foo!', 'foo'
    )

    include_examples(
      'end_with attributes', /f(o)+/, 'foo', 'f'
    )

    include_examples(
      'end_with attributes', /e(fg)+(x(abba){1,2}x)*[stu]/i, 'abcdefgfgxabbaabbaxT', 'abcdefgfgxabbaabbaxT.'
    )

    include_examples(
      'end_with attributes', 'bar', 'foobar', 'foobarbaz'
    )
  end

  shared_context 'with bot and server' do
    let(:server_name) { 'server_name' }
    let(:server_id) { 1 }
    let(:server) { instance_double(Discordrb::Server, 'server', name: server_name, id: server_id) }
    let(:bot) { instance_double(Discordrb::Bot, 'bot', server: server) }
  end

  shared_context 'with emoji' do
    let(:emoji_id) { 10 }
    let(:emoji_name) { 'emoji_name_1' }
    let(:emoji) { instance_double(Discordrb::Emoji, 'emoji', id: emoji_id, name: emoji_name) }
  end

  shared_examples 'ServerEvent' do
    describe '#initialize' do
      it 'sets bot' do
        expect(event.bot).to eq(bot)
      end

      it 'sets server' do
        expect(event.server).to eq(server)
      end
    end
  end

  shared_examples 'ServerEventHandler' do
    describe '#matches?' do
      it 'matches server names' do
        handler = described_class.new({ server: server_name }, nil)
        expect(handler).to be_matching(event)
      end

      it 'matches server ids' do
        handler = described_class.new({ server: server_id }, nil)
        expect(handler).to be_matching(event)
      end

      it 'matches server object' do
        handler = described_class.new({ server: server }, nil)
        expect(handler).to be_matching(event)
      end
    end
  end

  shared_examples 'ServerEmojiEventHandler' do
    describe '#matches?' do
      it 'matches emoji id' do
        handler = described_class.new({ id: emoji_id }, nil)
        expect(handler).to be_matching(event)
      end

      it 'matches emoji name' do
        handler = described_class.new({ name: emoji_name }, nil)
        expect(handler).to be_matching(event)
      end
    end
  end

  describe Discordrb::Events::ServerEvent do
    subject(:event) do
      described_class.new({ server_id => nil }, bot)
    end

    include_context 'with bot and server'

    it_behaves_like 'ServerEvent'
  end

  describe Discordrb::Events::ServerEmojiCDEvent do
    subject(:event) do
      described_class.new(server, emoji, bot)
    end

    include_context 'with bot and server'
    let(:emoji) { double }

    it_behaves_like 'ServerEvent'

    describe '#initialize' do
      it 'sets emoji' do
        expect(event.emoji).to eq(emoji)
      end
    end
  end

  describe Discordrb::Events::ServerEmojiChangeEvent do
    subject(:event) do
      described_class.new(server, dispatch, bot)
    end

    include_context 'with bot and server'
    before do
      allow(server).to receive(:emoji).and_return({ emoji_1_id => nil, emoji_2_id => nil })
    end

    fixture :dispatch, %i[emoji dispatch]

    fixture_property :emoji_1_id, :dispatch, ['emojis', 0, 'id'], :to_i
    fixture_property :emoji_2_id, :dispatch, ['emojis', 1, 'id'], :to_i

    it_behaves_like 'ServerEvent'

    describe '#process_emoji' do
      it 'sets an array of Emoji' do
        expect(event.emoji).to eq([nil, nil])
      end
    end
  end

  describe Discordrb::Events::ServerEmojiUpdateEvent do
    subject(:event) do
      described_class.new(server, old_emoji, emoji, bot)
    end

    include_context 'with bot and server'
    let(:old_emoji) { double }
    let(:emoji) { double }

    it_behaves_like 'ServerEvent'

    describe '#initialize' do
      it 'sets emoji' do
        expect(event.emoji).to eq(emoji)
      end

      it 'sets old_emoji' do
        expect(event.old_emoji).to eq(old_emoji)
      end
    end
  end

  describe Discordrb::Events::ServerEventHandler do
    include_context 'with bot and server'
    let(:event) { instance_double(Discordrb::Events::ServerEvent, 'event', is_a?: true, server: server) }

    include_examples 'ServerEventHandler'
  end

  describe Discordrb::Events::ServerEmojiCDEventHandler do
    include_context 'with bot and server'
    include_context 'with emoji'
    let(:event) { instance_double(Discordrb::Events::ServerEmojiCDEvent, 'event', is_a?: true, emoji: emoji, server: server) }

    it_behaves_like 'ServerEventHandler'
    it_behaves_like 'ServerEmojiEventHandler'
  end

  describe Discordrb::Events::ServerEmojiUpdateEventHandler do
    include_context 'with bot and server'
    include_context 'with emoji'
    let(:emoji_name_two) { 'emoji_name_2' }
    let(:event) { instance_double(Discordrb::Events::ServerEmojiUpdateEvent, 'event', is_a?: true, emoji: emoji, old_emoji: old_emoji, server: server) }
    let(:old_emoji) { instance_double(Discordrb::Emoji, 'old emoji', id: emoji_id, name: emoji_name_two) }

    it_behaves_like 'ServerEventHandler'
    it_behaves_like 'ServerEmojiEventHandler'

    describe '#matches?' do
      it 'matches old emoji name' do
        handler = described_class.new({ old_name: emoji_name_two }, nil)
        expect(handler).to be_matching(event)
      end
    end
  end
end
