# frozen_string_literal: true

require 'discordrb'

describe Discordrb::API do
  describe '.icon_size' do
    it 'returns nil if argument is nil' do
      expect(Discordrb::API.icon_size(nil)).to be_nil
    end

    it 'returns a string if argument is an int' do
      expect(Discordrb::API.icon_size(16)).to be_a(String)
    end

    it 'returns a string in the correct format' do
      expect(Discordrb::API.icon_size(16)).to eq('?size=16')
    end
  end
end
