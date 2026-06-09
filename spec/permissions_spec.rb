# frozen_string_literal: true

require 'discordrb'

describe Discordrb::Permissions do
  subject { Discordrb::Permissions.new }

  describe Discordrb::Permissions::FLAGS do
    it 'creates a setter for each flag' do
      responds_to_methods = Discordrb::Permissions::FLAGS.map do |_, flag|
        subject.respond_to?(:"can_#{flag}=")
      end

      expect(responds_to_methods.all?).to eq true
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
            subject.instance_variable_get(:@foo),
            subject.instance_variable_get(:@bar)
          ]
        ).to eq [false, false]
      end
    end

    describe '.bits' do
      it 'returns the correct packed bits from an array of symbols' do
        expect(Discordrb::Permissions.bits(%i[foo bar])).to eq 3
      end
    end

    describe '#bits=' do
      it 'updates the cached value' do
        allow(subject).to receive(:init_vars)
        subject.bits = 1
        expect(subject.bits).to eq(1)
      end

      it 'calls #init_vars' do
        expect(subject).to receive(:init_vars)
        subject.bits = 0
      end
    end

    describe '#initialize' do
      it 'initializes with 0 bits' do
        expect(subject.bits).to eq 0
      end

      it 'can initialize with an array of symbols' do
        instance = Discordrb::Permissions.new %i[foo bar]
        expect(instance.bits).to eq 3
      end

      it 'calls #init_vars' do
        expect_any_instance_of(Discordrb::Permissions).to receive(:init_vars)
        subject
      end
    end

    describe '#defined_permissions' do
      it 'returns the defined permissions' do
        instance = Discordrb::Permissions.new 3
        expect(instance.defined_permissions).to eq %i[foo bar]
      end
    end
  end
end

class ExampleCalculator
  include Discordrb::PermissionCalculator
  attr_accessor :server, :roles, :id
end

describe Discordrb::PermissionCalculator do
  subject { ExampleCalculator.new }

  describe '#defined_role_permission?' do
    it 'solves permissions (issue #607)' do
      everyone_role = double('everyone role', id: 0, position: 0, permissions: Discordrb::Permissions.new)
      role_a = double('role a', id: 1, position: 1, permissions: Discordrb::Permissions.new)
      role_b = double('role b', id: 2, position: 2, permissions: Discordrb::Permissions.new([:manage_messages]))
      data = load_data_file(:text_channel)
      channel = Discordrb::Channel.new(data, double('bot'), double('server', id: 123))

      allow(subject).to receive(:permission_overwrite)
        .with(:manage_messages, channel, everyone_role.id)
        .and_return(false)

      allow(subject).to receive(:permission_overwrite)
        .with(:manage_messages, channel, role_a.id)
        .and_return(true)

      allow(subject).to receive(:permission_overwrite)
        .with(:manage_messages, channel, role_b.id)
        .and_return(false)

      subject.server = double('server', everyone_role: everyone_role)
      subject.roles = [role_a, role_b]
      permission = subject.__send__(:defined_role_permission?, :manage_messages, channel)
      expect(permission).to eq true

      subject.roles = [role_b, role_a]
      permission = subject.__send__(:defined_role_permission?, :manage_messages, channel)
      expect(permission).to eq true
    end

    it 'takes overwrites into account' do
      everyone_role = double('everyone role', id: 0, position: 0, permissions: Discordrb::Permissions.new)
      role_a = double('role a', id: 1, position: 1, permissions: Discordrb::Permissions.new([:manage_messages]))
      role_b = double('role b', id: 2, position: 2, permissions: Discordrb::Permissions.new)
      data = load_data_file(:text_channel)
      data['permission_overwrites'] << {
        'deny' => Discordrb::Permissions.bits([:manage_messages]),
        'type' => 'role',
        'id' => role_a.id,
        'allow' => 0
      }
      data['permission_overwrites'] << {
        'deny' => 0,
        'type' => 'role',
        'id' => role_b.id,
        'allow' => Discordrb::Permissions.bits([:manage_messages])
      }

      channel = Discordrb::Channel.new(data, double('bot'), double('server', id: 123))

      subject.server = double('server', everyone_role: everyone_role)
      subject.roles = [role_a, role_b]

      subject.roles = [role_a]
      expect(subject.__send__(:defined_role_permission?, :manage_messages, channel)).to be false

      subject.roles = [role_a, role_b]
      expect(subject.__send__(:defined_role_permission?, :manage_messages, channel)).to be true
    end
  end

  describe '#defined_permission?' do
    context "when roles have allow permissions and channel's permission overwrites {everyone -> deny}" do
      it 'returns no access' do
        everyone_role = double('everyone role', id: 0, position: 0, permissions: Discordrb::Permissions.new([:read_messages]))
        role_a = double('role a', id: 1, position: 1, permissions: Discordrb::Permissions.new(%i[read_messages read_message_history]))
        role_b = double('role b', id: 2, position: 2, permissions: Discordrb::Permissions.new([:manage_messages]))

        data = load_data_file(:text_channel)
        data['permission_overwrites'] << {
          'deny' => Discordrb::Permissions.bits([:read_messages]),
          'type' => 'role',
          'id' => everyone_role.id,
          'allow' => 0
        }
        channel = Discordrb::Channel.new(data, double('bot'), double('server', id: 123))

        subject.server = double('server', everyone_role: everyone_role)
        subject.roles = [role_a, role_b]
        subject.id = 1
        expect(subject.__send__(:defined_permission?, :read_messages, channel)).to be false
      end
    end

    context "when roles have allow permissions and channel's permission overwrites {everyone -> deny, role_a -> allow}" do
      it 'returns full access' do
        everyone_role = double('everyone role', id: 0, position: 0, permissions: Discordrb::Permissions.new([:read_messages]))
        role_a = double('role a', id: 1, position: 1, permissions: Discordrb::Permissions.new(%i[read_messages read_message_history]))
        role_b = double('role b', id: 2, position: 2, permissions: Discordrb::Permissions.new([:manage_messages]))

        data = load_data_file(:text_channel)
        data['permission_overwrites'] << {
          'deny' => Discordrb::Permissions.bits([:read_messages]),
          'type' => 'role',
          'id' => everyone_role.id,
          'allow' => 0
        }
        data['permission_overwrites'] << {
          'deny' => 0,
          'type' => 'role',
          'id' => role_a.id,
          'allow' => Discordrb::Permissions.bits([:read_messages])
        }
        channel = Discordrb::Channel.new(data, double('bot'), double('server', id: 123))

        subject.server = double('server', everyone_role: everyone_role)
        subject.roles = [role_a, role_b]
        subject.id = 1
        expect(subject.__send__(:defined_permission?, :read_messages, channel)).to be true
      end
    end
  end
end
