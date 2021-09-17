# frozen_string_literal: true

require 'discordrb'

describe Discordrb::API::Channel do
  let(:token) { double('token', to_s: 'bot_token') }
  let(:channel_id) { instance_double(String, 'channel_id', to_s: 'channel_id') }

  describe '.get_reactions' do
    let(:message_id) { double('message_id', to_s: 'message_id') }
    let(:before_id) { double('before_id', to_s: 'before_id') }
    let(:after_id) { double('after_id', to_s: 'after_id') }

    before do
      allow(Discordrb::API).to receive(:request)
        .with(anything, channel_id, :get, kind_of(String), any_args)
    end

    it 'sends requests' do
      expect(Discordrb::API).to receive(:request)
        .with(
          anything,
          channel_id,
          :get,
          "#{Discordrb::API.api_base}/channels/#{channel_id}/messages/#{message_id}/reactions/test?limit=27&before=#{before_id}&after=#{after_id}",
          any_args
        )
      Discordrb::API::Channel.get_reactions(token, channel_id, message_id, 'test', before_id, after_id, 27)
    end

    it 'percent-encodes emoji' do
      expect(Discordrb::API).to receive(:request)
        .with(
          anything,
          channel_id,
          :get,
          "#{Discordrb::API.api_base}/channels/#{channel_id}/messages/#{message_id}/reactions/%F0%9F%91%8D?limit=27&before=#{before_id}&after=#{after_id}",
          any_args
        )
      Discordrb::API::Channel.get_reactions(token, channel_id, message_id, "\u{1F44D}", before_id, after_id, 27)
    end

    it 'uses the maximum limit of 100 if nil is provided' do
      expect(Discordrb::API).to receive(:request)
        .with(
          anything,
          channel_id,
          :get,
          "#{Discordrb::API.api_base}/channels/#{channel_id}/messages/#{message_id}/reactions/test?limit=100&before=#{before_id}&after=#{after_id}",
          any_args
        )
      Discordrb::API::Channel.get_reactions(token, channel_id, message_id, 'test', before_id, after_id, nil)
    end
  end
end
