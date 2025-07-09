# frozen_string_literal: true

require 'discordrb'

describe Discordrb::Permissions do
  subject(:permissions) { described_class.new }

  describe '::FLAGS' do
    it 'creates a setter for each flag' do
      responds_to_methods = described_class::FLAGS.map do |_, flag|
        permissions.respond_to?(:"can_#{flag}=")
      end

      expect(responds_to_methods.all?).to be true
    end

    it 'calls #write on its writer' do
      writer = instance_double(Discordrb::Role::RoleWriter, 'writer', write: nil)

      described_class.new(0, writer).can_read_messages = true
      expect(writer).to have_received(:write)
    end
  end

  context 'with FLAGS stubbed' do
    before do
      stub_const('Discordrb::Permissions::FLAGS', 0 => :foo, 1 => :bar)
    end

    describe '#init_vars' do
      it 'sets an attribute for each flag' do
        expect(
          [
            permissions.instance_variable_get(:@foo),
            permissions.instance_variable_get(:@bar)
          ]
        ).to eq [false, false]
      end
    end

    describe '.bits' do
      it 'returns the correct packed bits from an array of symbols' do
        expect(described_class.bits(%i[foo bar])).to eq 3
      end
    end

    describe '#bits=' do
      before do
        allow(permissions).to receive(:init_vars)
      end

      it 'updates the cached value' do
        permissions.bits = 1
        expect(permissions.bits).to eq(1)
      end

      it 'calls #init_vars' do
        permissions.bits = 0
        expect(permissions).to have_received(:init_vars)
      end
    end

    describe '#initialize' do
      it 'initializes with 0 bits' do
        expect(permissions.bits).to eq 0
      end

      it 'can initialize with an array of symbols' do
        instance = described_class.new %i[foo bar]
        expect(instance.bits).to eq 3
      end

      it 'calls #init_vars' do
        permissions = described_class.allocate
        allow(permissions).to receive(:init_vars)
        permissions.send :initialize
        expect(permissions).to have_received(:init_vars)
      end
    end

    describe '#defined_permissions' do
      it 'returns the defined permissions' do
        instance = described_class.new 3
        expect(instance.defined_permissions).to eq %i[foo bar]
      end
    end
  end
end
