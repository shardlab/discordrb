# frozen_string_literal: true

require 'discordrb'

describe Discordrb::Emoji do
  let(:bot) { double('bot') }

  subject(:emoji) do
    server = double('server', role: double)

    described_class.new(emoji_data, bot, server)
  end

  fixture :emoji_data, %i[emoji]

  describe '#mention' do
    context 'with an animated emoji' do
      it 'serializes with animated flag' do
        allow(emoji).to receive(:animated).and_return(true)

        expect(emoji.mention).to eq '<a:rubytaco:315242245274075157>'
      end
    end

    context 'with a unicode emoji' do
      it 'serializes' do
        allow(emoji).to receive(:id).and_return(nil)

        expect(emoji.mention).to eq 'rubytaco'
      end
    end

    it 'serializes' do
      expect(emoji.mention).to eq '<:rubytaco:315242245274075157>'
    end
  end

  describe '#to_reaction' do
    it 'serializes to reaction format' do
      expect(emoji.to_reaction).to eq 'rubytaco:315242245274075157'
    end

    context 'when ID is nil' do
      it 'serializes to reaction format without custom emoji ID character' do
        allow(emoji).to receive(:id).and_return(nil)

        expect(emoji.to_reaction).to eq 'rubytaco'
      end
    end
  end

  describe '#icon_url' do
    context 'when emoji is animated' do
      before { allow(emoji).to receive(:animated).and_return(true) }
      it 'returns the url for the gif if no format is specified' do
        expect(emoji.icon_url).to eq 'https://cdn.discordapp.com/emojis/315242245274075157.gif'
      end

      it 'returns the url for the specified format' do
        expect(emoji.icon_url(format: 'webp')).to eq 'https://cdn.discordapp.com/emojis/315242245274075157.webp'
      end

      it 'returns the url for the specified size' do
        expect(emoji.icon_url(size: 128)).to eq 'https://cdn.discordapp.com/emojis/315242245274075157.gif?size=128'
      end

      it 'returns the url for the specified format and size' do
        expect(emoji.icon_url(format: 'webp', size: 128)).to eq 'https://cdn.discordapp.com/emojis/315242245274075157.webp?size=128'
      end
    end

    context 'when emoji is not animated' do
      it 'returns the url for the webp if no format is specified' do
        expect(emoji.icon_url).to eq 'https://cdn.discordapp.com/emojis/315242245274075157.webp'
      end

      it 'returns the url for the specified format' do
        expect(emoji.icon_url(format: 'png')).to eq 'https://cdn.discordapp.com/emojis/315242245274075157.png'
      end

      it 'returns the url for the specified size' do
        expect(emoji.icon_url(size: 128)).to eq 'https://cdn.discordapp.com/emojis/315242245274075157.webp?size=128'
      end

      it 'returns the url for the specified format and size' do
        expect(emoji.icon_url(format: 'png', size: 128)).to eq 'https://cdn.discordapp.com/emojis/315242245274075157.png?size=128'
      end
    end
  end
end
