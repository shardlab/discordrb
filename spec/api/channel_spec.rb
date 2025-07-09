# frozen_string_literal: true

require 'discordrb'

describe Discordrb::API::Channel do
  let(:token) { instance_double(String, 'token', to_s: 'bot_token') }
  let(:channel_id) { instance_double(String, 'channel_id', to_s: 'channel_id') }
  let(:message_id) { instance_double(String, 'message_id', to_s: 'message_id') }

  before do
    allow(Discordrb::API).to receive(:request).with(anything, channel_id, instance_of(Symbol), any_args)
  end

  describe '.get_reactions' do
    let(:before_id) { instance_double(String, 'before_id', to_s: 'before_id') }
    let(:after_id) { instance_double(String, 'after_id', to_s: 'after_id') }

    it 'sends requests' do
      described_class.get_reactions(token, channel_id, message_id, 'test', before_id, after_id, 27)
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
      described_class.get_reactions(token, channel_id, message_id, "\u{1F44D}", before_id, after_id, 27)
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
      described_class.get_reactions(token, channel_id, message_id, 'test', before_id, after_id, nil)
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

  describe '.delete_all_emoji_reactions' do
    let(:emoji) { "\u{1F525}" }

    it 'sends requests' do
      described_class.delete_all_emoji_reactions(token, channel_id, message_id, emoji)
      expect(Discordrb::API).to have_received(:request)
        .with(
          anything,
          channel_id,
          :delete,
          "#{Discordrb::API.api_base}/channels/#{channel_id}/messages/#{message_id}/reactions/#{URI.encode_www_form_component(emoji)}",
          any_args
        )
    end
  end
end
