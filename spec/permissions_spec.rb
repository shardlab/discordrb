# frozen_string_literal: true

require 'discordrb'

describe Discordrb::Permissions do
  # TODO: excluding one instance from this cop for now, but this section probably deserves a closer look
  subject(:permissions_list) { Discordrb::Permissions.new } # rubocop:disable RSpec/DescribedClass

  describe Discordrb::Permissions::FLAGS do
    it 'creates a setter for each flag' do
      responds_to_methods = described_class.map do |_, flag|
        permissions_list.respond_to?(:"can_#{flag}=")
      end

      expect(responds_to_methods.all?).to be true
    end

    it 'calls #write on its writer' do
      writer = double
      expect(writer).to receive(:write)

      Discordrb::Permissions.new(0, writer).can_read_messages = true
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
            permissions_list.instance_variable_get(:@foo),
            permissions_list.instance_variable_get(:@bar)
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
      it 'updates the cached value' do
        allow(permissions_list).to receive(:init_vars)
        permissions_list.bits = 1
        expect(permissions_list.bits).to eq(1)
      end

      it 'calls #init_vars' do
        expect(permissions_list).to receive(:init_vars)
        permissions_list.bits = 0
      end
    end

    describe '#initialize' do
      it 'initializes with 0 bits' do
        expect(permissions_list.bits).to eq 0
      end

      it 'can initialize with an array of symbols' do
        instance = described_class.new %i[foo bar]
        expect(instance.bits).to eq 3
      end

      it 'calls #init_vars' do
        expect_any_instance_of(described_class).to receive(:init_vars)
        permissions_list
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

class ExampleCalculator
  include Discordrb::PermissionCalculator
  attr_accessor :server, :roles
end

describe Discordrb::PermissionCalculator do
  subject(:example_calculator) { ExampleCalculator.new }

  describe '#defined_role_permission?' do
    it 'solves permissions (issue #607)' do
      everyone_role = instance_double(Discordrb::Role, id: 0, position: 0, permissions: Discordrb::Permissions.new)
      role_a = instance_double(Discordrb::Role, id: 1, position: 1, permissions: Discordrb::Permissions.new)
      role_b = instance_double(Discordrb::Role, id: 2, position: 2, permissions: Discordrb::Permissions.new([:manage_messages]))

      channel = instance_double(Discordrb::Channel)
      allow(example_calculator).to receive(:permission_overwrite)
        .with(:manage_messages, channel, everyone_role.id)
        .and_return(false)

      allow(example_calculator).to receive(:permission_overwrite)
        .with(:manage_messages, channel, role_a.id)
        .and_return(true)

      allow(example_calculator).to receive(:permission_overwrite)
        .with(:manage_messages, channel, role_b.id)
        .and_return(false)

      example_calculator.server = instance_double(Discordrb::Server, everyone_role: everyone_role)
      example_calculator.roles = [role_a, role_b]
      permission = example_calculator.__send__(:defined_role_permission?, :manage_messages, channel)
      expect(permission).to be true

      example_calculator.roles = [role_b, role_a]
      permission = example_calculator.__send__(:defined_role_permission?, :manage_messages, channel)
      expect(permission).to be true
    end

    it 'takes overwrites into account' do
      everyone_role = instance_double(Discordrb::Role, id: 0, position: 0, permissions: Discordrb::Permissions.new)
      role_a = instance_double(Discordrb::Role, id: 1, position: 1, permissions: Discordrb::Permissions.new([:manage_messages]))
      role_b = instance_double(Discordrb::Role, id: 2, position: 2, permissions: Discordrb::Permissions.new)
      channel = instance_double(Discordrb::Channel)

      example_calculator.server = instance_double(Discordrb::Server, everyone_role: everyone_role)
      example_calculator.roles = [role_a, role_b]

      allow(example_calculator).to receive(:permission_overwrite).and_return(nil)

      allow(example_calculator).to receive(:permission_overwrite)
        .with(:manage_messages, channel, role_a.id)
        .and_return(:deny)

      allow(example_calculator).to receive(:permission_overwrite)
        .with(:manage_messages, channel, role_b.id)
        .and_return(:allow)

      example_calculator.roles = [role_a]
      expect(example_calculator.__send__(:defined_role_permission?, :manage_messages, channel)).to be false

      example_calculator.roles = [role_a, role_b]
      expect(example_calculator.__send__(:defined_role_permission?, :manage_messages, channel)).to be true
    end
  end
end
