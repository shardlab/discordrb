# frozen_string_literal: true

require "discordrb"

describe Discordrb::API::Channel do
  let(:token) { double('token') }
  let(:channel_id) { instance_double(String, 'channel_id') }

  before do
    allow(token).to receive(:to_s).and_return('bot_token')
    allow(channel_id).to receive(:to_s).and_return('channel_id')
  end

  describe '.get_reactions' do
    let(:message_id) { double('message_id') }
    let(:before_id) { double('before_id') }
    let(:after_id) { double('after_id') }

    before do
      allow(message_id).to receive(:to_s).and_return('message_id')
      allow(before_id).to receive(:to_s).and_return('before_id')
      allow(after_id).to receive(:to_s).and_return('after_id')

      allow(Discordrb::API).to receive(:request)
        .with(anything, channel_id, :get, kind_of(String), any_args)
    end    

    it 'sends requests' do
      Discordrb::API::Channel.get_reactions(token, channel_id, message_id, 'test', before_id, after_id, 27)
      expect(Discordrb::API).to have_received(:request)
        .with(
          anything,
          channel_id,
          :get,
          "#{Discordrb::API.api_base}/channels/#{channel_id}/messages/#{message_id}/reactions/test?limit=27&before=#{before_id}&after=#{after_id}",
          any_args
        )
    end

    it 'percent-encodes emoji' do
      Discordrb::API::Channel.get_reactions(token, channel_id, message_id, "\u{1F44D}", before_id, after_id, 27)
      expect(Discordrb::API).to have_received(:request)
        .with(
          anything,
          channel_id,
          :get,
          "#{Discordrb::API.api_base}/channels/#{channel_id}/messages/#{message_id}/reactions/%F0%9F%91%8D?limit=27&before=#{before_id}&after=#{after_id}",
          any_args
        )
    end

    it 'uses the maximum limit of 100 if nil is provided' do
      Discordrb::API::Channel.get_reactions(token, channel_id, message_id, "test", before_id, after_id, nil)
      expect(Discordrb::API).to have_received(:request)
        .with(
          anything,
          channel_id,
          :get,
          "#{Discordrb::API.api_base}/channels/#{channel_id}/messages/#{message_id}/reactions/test?limit=100&before=#{before_id}&after=#{after_id}",
          any_args
        )
    end
  end
end