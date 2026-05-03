# frozen_string_literal: true

module Discordrb
  module Voice
  end
end

require 'discordrb/voice/network'

RSpec.describe Discordrb::Voice::VoiceWS do
  let(:profile) { instance_double('Profile', id: 123) }
  let(:server) { instance_double('Server', id: 456) }
  let(:member) { instance_double('Member', id: 789) }
  let(:channel) { instance_double('Channel', server: server, users: [member], id: 555) }
  let(:bot) { instance_double('Bot', profile: profile) }
  let(:client) { instance_double(Discordrb::WebSocket) }
  let(:udp) { instance_double(Discordrb::Voice::VoiceUDP) }

  subject(:voice_ws) { described_class.new(channel, bot, 'token', 'session', 'endpoint') }

  before do
    allow(bot).to receive(:debug)
    allow(bot).to receive(:warn)

    voice_ws.instance_variable_set(:@client, client)
    voice_ws.instance_variable_set(:@udp, udp)

    allow(udp).to receive(:secret_key=)
    allow(udp).to receive(:mode=)
    allow(udp).to receive(:send_discovery)
    allow(udp).to receive(:connect)
    allow(udp).to receive(:send)
  end

  describe '#send_init' do
    it 'advertises the maximum DAVE protocol version when libdave is available' do
      stub_const('Discordrb::Voice::LIBDAVE_AVAILABLE', true)
      stub_const('Discordrb::Voice::DAVE', double(max_supported_protocol_version: 1))

      expect(client).to receive(:send) do |payload, type|
        expect(type).to eq(:text)

        data = JSON.parse(payload)
        expect(data).to include('op' => Discordrb::Voice::Opcodes::IDENTIFY)
        expect(data.fetch('d')).to include(
          'server_id' => 456,
          'user_id' => 123,
          'session_id' => 'session',
          'token' => 'token',
          'max_dave_protocol_version' => 1
        )
      end

      voice_ws.send_init(456, 123, 'session', 'token')
    end
  end

  describe 'DAVE binary message handling' do
    let(:session) { instance_double('DAVE::Session') }

    before do
      voice_ws.instance_variable_set(:@pending_dave_session, session)
    end

    it 'passes external sender payloads to the DAVE session' do
      expect(session).to receive(:external_sender=).with('sender-package')

      voice_ws.send(
        :websocket_binary_message,
        "#{[0, 1, Discordrb::Voice::Opcodes::DAVE_MLS_EXTERNAL_SENDER].pack('C*')}sender-package"
      )
    end

    it 'sends commit/welcome data returned from proposal processing as a binary opcode' do
      expect(session).to receive(:process_proposals).with('proposal-bytes', array_including('123', '789')).and_return('commit')
      expect(client).to receive(:send).with("#{Discordrb::Voice::Opcodes::DAVE_MLS_COMMIT_WELCOME.chr}commit", :binary)

      voice_ws.send(
        :websocket_binary_message,
        "#{[0, 1, Discordrb::Voice::Opcodes::DAVE_MLS_PROPOSALS].pack('C*')}proposal-bytes"
      )
    end
  end

  describe 'DAVE transitions' do
    let(:session) { instance_double('DAVE::Session', protocol_version: 1) }
    let(:commit_result) { instance_double('DAVE::CommitResult', failed?: false, ignored?: false) }

    before do
      voice_ws.instance_variable_set(:@dave_session, session)
      voice_ws.instance_variable_set(:@pending_transition_protocol_version, 1)
      allow(session).to receive(:process_commit).with('commit-bytes').and_return(commit_result)
    end

    it 'marks a processed commit ready and activates DAVE on execute' do
      expect(client).to receive(:send) do |payload, type|
        expect(type).to eq(:text)

        data = JSON.parse(payload)
        expect(data).to include('op' => Discordrb::Voice::Opcodes::DAVE_TRANSITION_READY)
        expect(data.fetch('d')).to include('transition_id' => 7)
      end

      voice_ws.send(
        :websocket_binary_message,
        "#{[0, 1, Discordrb::Voice::Opcodes::DAVE_MLS_ANNOUNCE_COMMIT_TRANSITION].pack('C*')}#{[7].pack('n')}commit-bytes"
      )

      expect(udp).to receive(:send).with(:activate_dave!, session, 123)
      voice_ws.send(:handle_dave_execute_transition, 7)
    end
  end
end
