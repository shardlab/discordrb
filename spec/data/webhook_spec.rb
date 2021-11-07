# frozen_string_literal: true

require 'discordrb'

describe Discordrb::Webhook do
  let(:token) { double('token') }
  let(:reason) { double('reason') }
  let(:server) { double('server', member: double) }
  let(:channel) { double('channel', server: server) }
  let(:bot) { double('bot', channel: channel, token: token) }

  subject(:webhook) do
    described_class.new(webhook_data, bot)
  end

  fixture :webhook_data, %i[webhook]
  fixture_property :webhook_name, :webhook_data, ['name']
  fixture_property :webhook_channel_id, :webhook_data, ['channel_id'], :to_i
  fixture_property :webhook_id, :webhook_data, ['id'], :to_i
  fixture_property :webhook_token, :webhook_data, ['token']
  fixture_property :webhook_avatar, :webhook_data, ['avatar']

  fixture :update_name_data, %i[webhook update_name]
  fixture_property :edited_webhook_name, :update_name_data, ['name']

  fixture :update_avatar_data, %i[webhook update_avatar]
  fixture_property :edited_webhook_avatar, :update_channel_data, ['avatar']

  fixture :update_channel_data, %i[webhook update_channel]
  fixture_property :edited_webhook_channel_id, :update_channel_data, ['channel_id']

  fixture :avatar_data, %i[avatar]
  fixture_property :avatar_string, :avatar_data, ['avatar']

  describe '#initialize' do
    it 'sets readers' do
      expect(webhook.name).to eq webhook_name
      expect(webhook.id).to eq webhook_id
      expect(webhook.token).to eq webhook_token
      expect(webhook.avatar).to eq webhook_avatar
      expect(webhook.server).to eq server
      expect(webhook.channel).to eq channel
    end

    context 'when webhook from a token' do
      before { webhook.instance_variable_set(:@owner, nil) }
      it 'doesn\'t set owner' do
        expect(webhook.owner).to eq nil
      end
    end

    context 'when webhook is from auth' do
      context 'when owner cached' do
        let(:member) { double('member') }
        let(:server) { double('server', member: member) }

        it 'sets owner from cache' do
          expect(webhook.owner).to eq member
        end
      end

      context 'when owner not cached' do
        let(:server) { double('server', member: nil) }
        let(:user) { double('user') }
        let(:bot) { double('bot', channel: channel, ensure_user: user) }

        it 'gets user' do
          expect(webhook.owner).to eq user
        end
      end
    end
  end

  describe '#avatar=' do
    it 'calls update_webhook' do
      expect(webhook).to receive(:update_webhook).with(avatar: avatar_string)
      webhook.avatar = avatar_string
    end
  end

  describe '#delete_avatar' do
    it 'calls update_webhook' do
      expect(webhook).to receive(:update_webhook).with(avatar: nil)
      webhook.delete_avatar
    end
  end

  describe '#channel=' do
    it 'calls update_webhook' do
      expect(webhook).to receive(:update_webhook).with(channel_id: edited_webhook_channel_id.to_i)
      webhook.channel = edited_webhook_channel_id
    end
  end

  describe '#name=' do
    it 'calls update_webhook' do
      expect(webhook).to receive(:update_webhook).with(name: edited_webhook_name)
      webhook.name = edited_webhook_name
    end
  end

  describe '#update' do
    it 'calls update_webhook' do
      expect(webhook).to receive(:update_webhook).with(avatar: avatar_string, channel_id: edited_webhook_channel_id.to_i, name: edited_webhook_name, reason: reason)
      webhook.update(avatar: avatar_string, channel: edited_webhook_channel_id, name: edited_webhook_name, reason: reason)
    end
  end

  describe '#delete' do
    context 'when webhook is from auth' do
      it 'calls the API' do
        expect(Discordrb::API::Webhook).to receive(:delete_webhook).with(token, webhook_id, reason)
        webhook.delete(reason)
      end
    end

    context 'when webhook is from token' do
      before { webhook.instance_variable_set(:@owner, nil) }

      it 'calls the token API' do
        expect(Discordrb::API::Webhook).to receive(:token_delete_webhook).with(webhook_token, webhook_id, reason)
        webhook.delete(reason)
      end
    end
  end

  describe '#avatar_url' do
    context 'avatar is set' do
      it 'calls the correct API helper' do
        expect(Discordrb::API::User).to receive(:avatar_url).with(webhook_id, webhook_avatar)
        webhook.avatar_url
      end
    end

    context 'avatar is not set' do
      before { webhook.instance_variable_set(:@avatar, nil) }

      it 'calls the correct API helper' do
        expect(Discordrb::API::User).to receive(:default_avatar)
        webhook.avatar_url
      end
    end
  end

  describe '#inspect' do
    it 'describes the webhook' do
      expect(webhook.inspect).to eq "<Webhook name=#{webhook_name} id=#{webhook_id}>"
    end
  end

  describe '#token?' do
    context 'when webhook is from auth' do
      it 'returns false' do
        expect(webhook.token?).to eq false
      end
    end

    context 'when webhook is from token' do
      before { webhook.instance_variable_set(:@owner, nil) }
      it 'returns true' do
        expect(webhook.token?).to eq true
      end
    end
  end

  describe '#avatarise' do
    context 'avatar responds to read' do
      it 'returns encoded' do
        avatar = double('avatar', read: 'text')
        expect(webhook.send(:avatarise, avatar)).to eq "data:image/jpg;base64,#{Base64.strict_encode64('text')}"
      end
    end

    context 'avatar does not respond to read' do
      it 'returns itself' do
        avatar = double('avatar')
        expect(webhook.send(:avatarise, avatar)).to eq avatar
      end
    end
  end

  describe '#update_internal' do
    it 'sets name' do
      name = double('name')
      webhook.send(:update_internal, 'name' => name)
      expect(webhook.instance_variable_get(:@name)).to eq name
    end

    it 'sets avatar' do
      avatar = double('avatar')
      webhook.send(:update_internal, 'avatar' => avatar)
      expect(webhook.instance_variable_get(:@avatar_id)).to eq avatar
    end

    it 'sets channel' do
      channel = double('channel')
      channel_id = double('channel_id')
      allow(bot).to receive(:channel).with(channel_id).and_return(channel)
      webhook.send(:update_internal, 'channel_id' => channel_id)
      expect(webhook.instance_variable_get(:@channel)).to eq channel
    end
  end

  describe '#update_webhook' do
    context 'API returns valid data' do
      it 'calls update_internal' do
        webhook
        data = double('data', :[] => double)
        allow(JSON).to receive(:parse).and_return(data)
        allow(Discordrb::API::Webhook).to receive(:update_webhook)
        expect(webhook).to receive(:update_internal).with(data)
        webhook.send(:update_webhook, double('data', delete: reason))
      end
    end

    context 'API returns error' do
      it 'doesn\'t call update_internal' do
        webhook
        data = double('data', :[] => nil)
        allow(JSON).to receive(:parse).and_return(data)
        allow(Discordrb::API::Webhook).to receive(:update_webhook)
        expect(webhook).to_not receive(:update_internal)
        webhook.send(:update_webhook, double('data', delete: reason))
      end
    end

    context 'when webhook is from auth' do
      it 'calls auth API' do
        webhook
        data = double('data', delete: reason)
        allow(JSON).to receive(:parse).and_return(double('received_data', :[] => double))
        expect(Discordrb::API::Webhook).to receive(:update_webhook).with(token, webhook_id, data, reason)
        webhook.send(:update_webhook, data)
      end
    end

    context 'when webhook is from token' do
      before { webhook.instance_variable_set(:@owner, nil) }

      it 'calls token API' do
        data = double('data', delete: reason)
        allow(JSON).to receive(:parse).and_return(double('received_data', :[] => double))
        expect(Discordrb::API::Webhook).to receive(:token_update_webhook).with(webhook_token, webhook_id, data, reason)
        webhook.send(:update_webhook, data)
      end
    end
  end

  describe '#execute' do
    let(:resp) { instance_double(RestClient::Response) }
    let(:data) { instance_double(Hash) }

    before do
      allow(Discordrb::API::Webhook).to receive(:token_execute_webhook)
    end

    context 'when there is no token' do
      let(:tokenless_webhook) { webhook.clone }

      before do
        tokenless_webhook.instance_variable_set(:@token, nil)
      end

      it 'raises an UnauthorizedWebhook error' do
        expect { tokenless_webhook.execute }.to raise_error(Discordrb::Errors::UnauthorizedWebhook)
      end
    end

    context 'when no builder is provided' do
      it 'creates a new builder' do
        expect { |b| webhook.execute(wait: false, &b) }.to yield_with_args(instance_of(Discordrb::Webhooks::Builder), instance_of(Discordrb::Webhooks::View))
      end
    end

    it 'merges kwargs with builder data' do
      content = instance_double(String)
      username = instance_double(String)

      builder = Discordrb::Webhooks::Builder.new(content: content)

      webhook.execute(username: username, builder: builder, wait: false)

      expect(Discordrb::API::Webhook).to have_received(:token_execute_webhook).with(anything, anything, false, content, username, any_args)
    end

    context 'when wait is true' do
      before do
        allow(Discordrb::API::Webhook).to receive(:token_execute_webhook).and_return(resp)
        allow(Discordrb::Message).to receive(:new)
        allow(JSON).to receive(:parse).and_call_original
        allow(JSON).to receive(:parse).with(resp).and_return(data)
      end

      it 'creates a Message object with the response' do
        webhook.execute(wait: true)

        expect(Discordrb::Message).to have_received(:new).with(data, bot)
      end
    end
  end

  describe '#edit_message' do
    let(:message) { instance_double(String, resolve_id: message_id) }
    let(:message_id) { instance_double(Integer) }
    let(:resp) { instance_double(RestClient::Response) }
    let(:data) { instance_double(Hash) }

    before do
      allow(Discordrb::API::Webhook).to receive(:token_edit_message).with(any_args).and_return(resp)
      allow(JSON).to receive(:parse).with(anything).and_call_original
      allow(JSON).to receive(:parse).with(resp).and_return(data)
      allow(Discordrb::Message).to receive(:new).with(any_args).and_return(nil)
    end

    context 'when there is no token' do
      let(:tokenless_webhook) { webhook.clone }

      before do
        tokenless_webhook.instance_variable_set(:@token, nil)
      end

      it 'raises an UnauthorizedWebhook error' do
        expect { tokenless_webhook.edit_message(message) }.to raise_error(Discordrb::Errors::UnauthorizedWebhook)
      end
    end

    context 'when no builder is provided' do
      it 'creates a new builder' do
        expect { |b| webhook.edit_message(message, &b) }.to yield_with_args(
          instance_of(Discordrb::Webhooks::Builder),
          instance_of(Discordrb::Webhooks::View)
        )
      end
    end

    it 'merges kwargs with builder data' do
      content = instance_double(String)
      embeds = instance_double(Array)

      builder = Discordrb::Webhooks::Builder.new(content: content)

      webhook.edit_message(message, embeds: embeds, builder: builder)

      expect(Discordrb::API::Webhook).to have_received(:token_edit_message).with(webhook.token, webhook.id, message_id, content, embeds, nil, [])
    end

    it 'returns an updated Message object' do
      msg = instance_double(Discordrb::Message)
      allow(Discordrb::Message).to receive(:new).with(data, bot).and_return(msg)

      expect(webhook.edit_message(message)).to be msg
    end
  end

  describe '#delete_message' do
    let(:message) { instance_double(Discordrb::Message, resolve_id: message_id) }
    let(:message_id) { instance_double(Integer) }

    before do
      allow(Discordrb::API::Webhook).to receive(:token_delete_message).with(any_args)
    end

    context 'when there is no token' do
      let(:tokenless_webhook) { webhook.clone }

      before do
        tokenless_webhook.instance_variable_set(:@token, nil)
      end

      it 'raises an UnauthorizedWebhook error' do
        expect { tokenless_webhook.delete_message(message_id) }.to raise_error(Discordrb::Errors::UnauthorizedWebhook)
      end
    end

    it 'calls token_delete_message' do
      webhook.delete_message(message)

      expect(Discordrb::API::Webhook).to have_received(:token_delete_message).with(webhook.token, webhook.id, message_id)
    end
  end
end
