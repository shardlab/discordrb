# frozen_string_literal: true

require 'discordrb'

class ExampleCalculator
  include Discordrb::PermissionCalculator
  attr_accessor :server, :roles
end

describe Discordrb::PermissionCalculator do
  subject(:calculator) { ExampleCalculator.new }

  # TODO: Rework tests to not rely on multiple expectations
  # rubocop:disable RSpec/MultipleExpectations
  describe '#defined_role_permission?' do
    it 'solves permissions (issue #607)' do
      everyone_role = instance_double(Discordrb::Role, 'everyone role', id: 0, position: 0, permissions: Discordrb::Permissions.new)
      role_a = instance_double(Discordrb::Role, 'role a', id: 1, position: 1, permissions: Discordrb::Permissions.new)
      role_b = instance_double(Discordrb::Role, 'role b', id: 2, position: 2, permissions: Discordrb::Permissions.new([:manage_messages]))

      channel = double
      allow(calculator).to receive(:permission_overwrite)
        .with(:manage_messages, channel, everyone_role.id)
        .and_return(false)

      allow(calculator).to receive(:permission_overwrite)
        .with(:manage_messages, channel, role_a.id)
        .and_return(true)

      allow(calculator).to receive(:permission_overwrite)
        .with(:manage_messages, channel, role_b.id)
        .and_return(false)

      calculator.server = instance_double(Discordrb::Server, 'server', everyone_role: everyone_role)
      calculator.roles = [role_a, role_b]
      permission = calculator.__send__(:defined_role_permission?, :manage_messages, channel)
      expect(permission).to be true

      calculator.roles = [role_b, role_a]
      permission = calculator.__send__(:defined_role_permission?, :manage_messages, channel)
      expect(permission).to be true
    end

    it 'takes overwrites into account' do
      everyone_role = instance_double(Discordrb::Role, 'everyone role', id: 0, position: 0, permissions: Discordrb::Permissions.new)
      role_a = instance_double(Discordrb::Role, 'role a', id: 1, position: 1, permissions: Discordrb::Permissions.new([:manage_messages]))
      role_b = instance_double(Discordrb::Role, 'role b', id: 2, position: 2, permissions: Discordrb::Permissions.new)
      channel = double

      calculator.server = instance_double(Discordrb::Server, 'server', everyone_role: everyone_role)
      calculator.roles = [role_a, role_b]

      allow(calculator).to receive(:permission_overwrite).and_return(nil)

      allow(calculator).to receive(:permission_overwrite)
        .with(:manage_messages, channel, role_a.id)
        .and_return(:deny)

      allow(calculator).to receive(:permission_overwrite)
        .with(:manage_messages, channel, role_b.id)
        .and_return(:allow)

      calculator.roles = [role_a]
      expect(calculator.__send__(:defined_role_permission?, :manage_messages, channel)).to be false

      calculator.roles = [role_a, role_b]
      expect(calculator.__send__(:defined_role_permission?, :manage_messages, channel)).to be true
    end
  end
  # rubocop:enable RSpec/MultipleExpectations
end
