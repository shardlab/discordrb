# frozen_string_literal: true

require 'discordrb'

describe Discordrb::Emoji do
  describe '#mention' do
    context 'When the emoji is unicode' do
      it 'returns the name of the emoji' do
        emoji = described_class.new({ 'name' => '🍄', 'animated' => false, 'id' => nil }, nil)

        expect(emoji.mention).to eq('🍄')
      end
    end

    context 'When the emoji is animated' do
      it 'mentions the emoji with the \'a\' property' do
        emoji = described_class.new({ 'name' => 'rubytaco', 'animated' => true, 'id' => '315242245274075157' }, nil)

        expect(emoji.mention).to eq('<a:rubytaco:315242245274075157>')
      end
    end

    context 'When the emoji is not animated' do
      it 'mentions the emoji without the \'a\' property' do
        emoji = described_class.new({ 'name' => 'rubytaco', 'animated' => false, 'id' => '315242245274075157' }, nil)

        expect(emoji.mention).to eq('<:rubytaco:315242245274075157>')
      end
    end
  end

  describe '#to_h' do
    context 'When the emoji is a unicode emoji' do
      it 'serializes the emoji with the \'name:\' key' do
        emoji = described_class.new({ 'name' => '🍄', 'animated' => false, 'id' => nil }, nil)

        expect(emoji.to_h).to eq({ name: '🍄' })
      end
    end

    context 'When the emoji is a custom emoji' do
      it 'serializes the emoji with the \'id:\' key' do
        emoji = described_class.new({ 'name' => 'rubytaco', 'animated' => true, 'id' => '315242245274075157' }, nil)

        expect(emoji.to_h).to eq({ id: 315_242_245_274_075_157 })
      end
    end
  end

  describe '#to_reaction' do
    context 'When the emoji is a unicode emoji' do
      it 'serializes the emoji in the unicode format' do
        emoji = described_class.new({ 'name' => '🍄', 'animated' => false, 'id' => nil }, nil)

        expect(emoji.to_reaction).to eq('🍄')
      end
    end

    context 'When the emoji is a custom emoji' do
      it 'serializes the emoji in the custom format' do
        emoji = described_class.new({ 'name' => 'rubytaco', 'animated' => true, 'id' => '315242245274075157' }, nil)

        expect(emoji.to_reaction).to eq('rubytaco:315242245274075157')
      end
    end
  end
end
