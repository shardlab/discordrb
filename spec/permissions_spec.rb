# frozen_string_literal: true

require 'discordrb'

describe Discordrb::Permissions do
  subject { Discordrb::Permissions.new }

  describe Discordrb::Permissions::MASKS do
    masks = Discordrb::Permissions::MASKS

    it 'Creates a method indicating if the bit is set' do
      expect(masks.all? { |name, _| subject.respond_to?(name) }).to eq(true)
    end

    it 'Creates a setter method to toggle each permission' do
      expect(masks.all? { |name, _| subject.respond_to?("can_#{name}=") }).to eq(true)
    end
  end

  describe '#initialize' do
    context 'With nothing passed' do
      it 'creates a new object with no bits set' do
        permissions = described_class.new

        expect(permissions.bits).to eq(0)
      end
    end

    context 'With a bitfield passed' do
      it 'creates a new object with exactly those bits' do
        permissions = described_class.new(268_443_648)

        expect(permissions.bits).to eq(268_443_648)
      end
    end

    context 'With an array of permissions passed' do
      it 'creates a new object with the bits for those permissions' do
        permissions = described_class.new(%i[manage_roles manage_messages connect])

        expect(permissions.bits).to eq(269_492_224)
      end
    end
  end

  describe '#==' do
    context 'When the other object has the same bits' do
      it 'returns true' do
        first = described_class.new(%i[manage_roles send_voice_messages])

        second = described_class.new(%i[manage_roles send_voice_messages])

        expect((first == second)).to eq(true)
      end
    end

    context 'When the other object has different bits' do
      it 'returns false' do
        first = described_class.new(%i[manage_roles send_voice_messages])

        second = described_class.new(%i[manage_roles view_monetization_analytics])

        expect((first == second)).to eq(false)
      end
    end

    context 'When the other is not a permission object' do
      it 'returns false' do
        first = described_class.new(%i[manage_roles send_voice_messages])

        second = '100'

        expect((first == second)).to eq(false)
      end
    end
  end

  describe '#bits=' do
    context 'When directly given a bitfield' do
      it 'directly sets the provided bitfield' do
        permissions = described_class.new

        permissions.bits = 139_586_764_800

        expect(permissions.bits).to eq(139_586_764_800)
      end
    end

    context 'When given a list of permissions' do
      it 'straight up converts them into a bitfield' do
        permissions = described_class.new

        permissions.bits = %i[embed_links attach_files mention_everyone]

        expect(permissions.bits).to eq(180_224)
      end
    end
  end

  describe '#defined_permissions' do
    it 'Converts the bitfield into a list of permissions' do
      permissions = described_class.new(3_145_730)

      expect(permissions.defined_permissions).to match_array(%i[connect speak kick_members])
    end
  end

  describe '.bits' do
    it 'Returns the bitfield for a given list of permissions' do
      permissions = described_class.bits([:manage_roles, 'use_slash_commands', :speak])

      expect(permissions).to eq(2_418_016_256)
    end
  end
end
