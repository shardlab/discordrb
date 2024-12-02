# frozen_string_literal: true

require 'discordrb'

describe Discordrb::Role do
  subject(:role) do
    described_class.new(role_data, bot, server)
  end

  let(:server) { instance_double(Discordrb::Server, 'server', id: double) }
  let(:bot) { instance_double(Discordrb::Bot, 'bot', token: double) }

  fixture :role_data, %i[role]

  describe '#sort_above' do
    context 'when other is nil' do
      it 'sorts the role to position 1' do
        allow(server).to receive(:update_role_positions)
        allow(server).to receive(:roles).and_return [
          instance_double(described_class, id: 0, position: 0),
          instance_double(described_class, id: 1, position: 1)
        ]

        new_position = role.sort_above
        expect(new_position).to eq 1
      end
    end

    context 'when other is given' do
      it 'sorts above other' do
        other = instance_double(described_class, id: 1, position: 1, resolve_id: 1)
        allow(server).to receive(:update_role_positions)
        allow(server).to receive_messages(role: other, roles: [
                                            instance_double(described_class, id: 0, position: 0),
                                            other,
                                            instance_double(described_class, id: 2, position: 2)
                                          ])

        new_position = role.sort_above(other)
        expect(new_position).to eq 2
      end
    end
  end
end
