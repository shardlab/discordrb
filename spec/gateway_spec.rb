# frozen_string_literal: true

require 'discordrb'

describe Discordrb::Gateway do
  subject(:gateway) { described_class.new(double('bot'), 'token') }

  before do
    @now = 1_000.0
    allow(Process).to receive(:clock_gettime).and_call_original
    allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC) { @now }
    allow(Discordrb::LOGGER).to receive(:info)
  end

  describe 'reconnect falloff' do
    # Runs the reconnect loop once per attempt, with the network and the wait
    # stubbed out, and returns how long it waited before each reconnect. Each
    # attempt is how many seconds its session lasted before the connection
    # dropped, or nil for a ten minute attempt that never got a session.
    def reconnect_delays(*attempts)
      delays = []
      allow(gateway).to receive(:sleep) { |seconds| delays << seconds }
      allow(gateway).to receive(:connect) do
        throw :done if attempts.empty?

        session_duration = attempts.shift
        gateway.__send__(:handle_dispatch, { 't' => 'RESUMED', 'd' => nil }) if session_duration
        @now += session_duration || 600
      end

      catch(:done) { gateway.__send__(:connect_loop) }
      delays
    end

    it 'should start again from the shortest delay after a session that lasted' do
      expect(reconnect_delays(3600, 3600, 3600)).to eq([1.0, 1.0, 1.0])
    end

    it 'should keep backing off while sessions keep dropping straight away' do
      expect(reconnect_delays(3600, 5, 5, 3600)).to eq([1.0, 1.5, 2.25, 1.0])
    end

    it 'should keep backing off while attempts fail to get a session' do
      expect(reconnect_delays(3600, nil, nil, 3600)).to eq([1.0, 1.5, 2.25, 1.0])
    end
  end
end
