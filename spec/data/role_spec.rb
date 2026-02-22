# frozen_string_literal: true

require 'discordrb'

describe Discordrb::Role do
  let(:server) { double('server', id: double) }
  let(:bot) { double('bot', token: double) }

  subject(:role) do
    described_class.new(role_data, bot, server)
  end

  fixture :role_data, %i[role]

  describe '#sort_above' do
    context 'when other is nil' do
      it 'sorts the role to position 1' do
        allow(role).to receive(:move).with(anything)
      end
    end

    context 'when other is given' do
      it 'sorts above other' do
        allow(role).to receive(:move).with(anything)
      end
    end
  end
end
