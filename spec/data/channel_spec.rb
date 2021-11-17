# frozen_string_literal: true

require 'discordrb'
require 'mock/api_mock'

using APIMock

describe Discordrb::Channel do
  subject(:channel) do
    allow(bot).to receive(:token).and_return('fake token')
    described_class.new(data, bot, server)
  end

  let(:data) { load_data_file(:text_channel) }
  # Instantiate the doubles here so we can apply mocks in the specs
  let(:bot) { instance_double(Discordrb::Bot, :bot) }
  let(:server) { instance_double(Discordrb::Server, :server, id: double) }

  shared_examples 'a Channel property' do |property_name|
    it 'calls #update_channel_data with data' do
      expect(channel).to receive(:update_channel_data).with(property_name => property_value)
      channel.__send__("#{property_name}=", property_value)
    end
  end

  describe '#name=' do
    it_behaves_like 'a Channel property', :name do
      let(:property_value) { instance_double(String, :name) }
    end
  end

  describe '#topic=' do
    it_behaves_like 'a Channel property', :topic do
      let(:property_value) { instance_double(String, :topic) }
    end
  end

  describe '#nsfw=' do
    context 'when toggled from false to true' do
      it_behaves_like 'a Channel property', :nsfw do
        let(:property_value) { true }
      end
    end

    context 'when toggled from true to false' do
      subject(:channel) { described_class.new(data.merge('nsfw' => true), double, server) }

      it_behaves_like 'a Channel property', :nsfw do
        let(:property_value) { false }
      end
    end
  end

  describe '#permission_overwrites=' do
    context 'when permissions_overwrites are explicitly set' do
      it_behaves_like 'a Channel property', :permission_overwrites do
        let(:property_value) { instance_double(Array, :permission_overwrites) }
      end
    end
  end

  describe '#rate_limit_per_user=' do
    it_behaves_like 'a Channel property', :rate_limit_per_user do
      let(:property_value) { 0 }
    end
  end

  describe '#slowmode?' do
    it 'works when the value is 0' do
      channel.instance_variable_set(:@rate_limit_per_user, 0)
      expect(channel).not_to be_slowmode
    end

    it "works when the value isn't 0" do
      channel.instance_variable_set(:@rate_limit_per_user, 5)
      expect(channel).to be_slowmode
    end
  end

  describe '#update_channel_data' do
    shared_examples('API call') do |property_name, num|
      it "calls the API with #{property_name}" do
        allow(channel).to receive(:update_data)
        allow(JSON).to receive(:parse)
        data = double(property_name)
        expectation = Array.new(num) { anything } << data << any_args
        expect(Discordrb::API::Channel).to receive(:update).with(*expectation)
        new_data = { property_name => data }
        channel.__send__(:update_channel_data, new_data)
      end
    end

    include_examples('API call', :name, 2)
    include_examples('API call', :topic, 3)
    include_examples('API call', :position, 4)
    include_examples('API call', :bitrate, 5)
    include_examples('API call', :user_limit, 6)
    include_examples('API call', :parent_id, 9)
    include_examples('API call', :rate_limit_per_user, 10)

    context 'when permission_overwrite are not set' do
      it 'does not send permission_overwrite' do
        allow(channel).to receive(:update_data)
        allow(JSON).to receive(:parse)
        new_data = instance_double(Hash, :new_data)
        allow(new_data).to receive(:[])
        allow(new_data).to receive(:[]).with(:permission_overwrites).and_return(false)
        expect(Discordrb::API::Channel).to receive(:update).with(any_args, nil, anything)
        channel.__send__(:update_channel_data, new_data)
      end
    end

    context 'when passed a boolean for nsfw' do
      it 'passes the boolean' do
        nsfw = double('nsfw')
        channel.instance_variable_set(:@nsfw, nsfw)
        allow(channel).to receive(:update_data)
        allow(JSON).to receive(:parse)
        new_data = instance_double(Hash, :new_data)
        allow(new_data).to receive(:[])
        allow(new_data).to receive(:[]).with(:nsfw).and_return(1)
        expect(Discordrb::API::Channel).to receive(:update).with(any_args, nsfw, anything, anything, anything)
        channel.__send__(:update_channel_data, new_data)
      end
    end

    context 'when passed a non-boolean for nsfw' do
      it 'passes the cached value' do
        nsfw = double('nsfw')
        channel.instance_variable_set(:@nsfw, nsfw)
        allow(channel).to receive(:update_data)
        allow(JSON).to receive(:parse)
        new_data = instance_double(Hash, :new_data)
        allow(new_data).to receive(:[])
        allow(new_data).to receive(:[]).with(:nsfw).and_return(1)
        expect(Discordrb::API::Channel).to receive(:update).with(any_args, nsfw, anything, anything, anything)
        channel.__send__(:update_channel_data, new_data)
      end
    end

    context 'when passed an Integer for rate_limit_per_user' do
      it 'passes the new value' do
        rate_limit_per_user = 5
        channel.instance_variable_set(:@rate_limit_per_user, rate_limit_per_user)
        allow(channel).to receive(:update_data)
        allow(JSON).to receive(:parse)
        new_data = instance_double(Hash, :new_data)
        allow(new_data).to receive(:[])
        allow(new_data).to receive(:[]).with(:rate_limit_per_user).and_return(5)
        expect(Discordrb::API::Channel).to receive(:update).with(any_args, rate_limit_per_user)
        channel.__send__(:update_channel_data, new_data)
      end
    end

    it 'calls #update_data with new data' do
      response_data = instance_double(Hash, :new_data)
      expect(channel).to receive(:update_data).with(response_data)
      allow(JSON).to receive(:parse).and_return(response_data)
      allow(Discordrb::API::Channel).to receive(:update)
      channel.__send__(:update_channel_data, double('data', :[] => double('sub_data', map: double)))
    end

    context 'when NoPermission is raised' do
      it 'does not call update_data' do
        allow(Discordrb::API::Channel).to receive(:update).and_raise(Discordrb::Errors::NoPermission)
        expect(channel).not_to receive(:update_data)
        begin
          channel.__send__(:update_channel_data, double('data', :[] => double('sub_data', map: double)))
        rescue Discordrb::Errors::NoPermission
          nil
        end
      end
    end
  end

  describe '#update_data' do
    shared_examples('update property data') do |property_name|
      context 'when we have new data' do
        it 'assigns the property' do
          new_data = instance_double(Hash, :new_data, :[] => nil, :key? => true)
          test_data = double('test_data')
          allow(new_data).to receive(:[]).with(property_name).and_return(test_data)
          expect { channel.__send__(:update_data, new_data) }.to change { channel.__send__(property_name) }.to test_data
        end
      end

      context 'when we don\'t have new data' do
        it 'keeps the cached value' do
          new_data = instance_double(Hash, :new_data, :[] => double('property'), key?: double)
          allow(new_data).to receive(:[]).with(property_name).and_return(nil)
          allow(new_data).to receive(:[]).with(property_name.to_s).and_return(nil)
          allow(channel).to receive(:process_permission_overwrites)
          expect { channel.__send__(:update_data, new_data) }.not_to(change { channel.__send__(property_name) })
        end
      end
    end

    include_examples('update property data', :name)
    include_examples('update property data', :topic)
    include_examples('update property data', :position)
    include_examples('update property data', :bitrate)
    include_examples('update property data', :user_limit)
    include_examples('update property data', :nsfw)
    include_examples('update property data', :parent_id)

    it 'calls process_permission_overwrites' do
      allow(Discordrb::API::Channel).to receive(:resolve).and_return('{}')
      expect(channel).to receive(:process_permission_overwrites)
      channel.__send__(:update_data)
    end

    context 'when data is not provided' do
      it 'requests it from the API' do
        allow(Discordrb::API::Channel).to receive(:resolve).and_return('{}')
        expect(Discordrb::API::Channel).to receive(:resolve)
        channel.__send__(:update_data)
      end
    end
  end

  describe '#delete_messages' do
    it 'fails with more than 100 messages' do
      messages = [*1..101]
      expect { channel.delete_messages(messages) }.to raise_error(ArgumentError)
    end

    it 'fails with less than 2 messages' do
      messages = [1]
      expect { channel.delete_messages(messages) }.to raise_error(ArgumentError)
    end

    it 'resolves message ids' do
      message = instance_double(Discordrb::Message, :message, resolve_id: double)
      num = 3
      messages = Array.new(num) { message } << 0
      allow(channel).to receive(:bulk_delete)
      expect(message).to receive(:resolve_id).exactly(num).times
      channel.delete_messages(messages)
    end

    it 'calls #bulk_delete' do
      messages = [1, 2, 3]
      expect(channel).to receive(:bulk_delete)
      channel.delete_messages(messages)
    end
  end

  describe '#bulk_delete' do
    it 'logs with old messages' do
      messages = [1, 2, 3, 4]
      allow(Discordrb::IDObject).to receive(:synthesise).and_return(3)
      allow(Discordrb::API::Channel).to receive(:bulk_delete_messages)
      expect(Discordrb::LOGGER).to receive(:warn).twice
      channel.__send__(:bulk_delete, messages)
    end

    context 'when in strict mode' do
      it 'raises ArgumentError with old messages' do
        messages = [1, 2, 3]
        expect { channel.__send__(:bulk_delete, messages, true) }.to raise_error(ArgumentError)
      end
    end

    context 'when in non-strict mode' do
      let(:@bot) { instance_double(Discordrb::Bot, :bot, token: 'token') }

      it 'removes old messages' do
        allow(Discordrb::IDObject).to receive(:synthesise).and_return(4)
        messages = [1, 2, 3, 4]

        # Suppresses some noisy WARN logging from specs output
        allow(Discordrb::LOGGER).to receive(:warn)
        allow(Discordrb::API::Channel).to receive(:bulk_delete_messages)

        channel.__send__(:delete_messages, messages)
        expect(messages).to eq [4]
      end
    end
  end

  describe '#process_permission_overwrites' do
    it 'assigns permission overwrites' do
      overwrite = instance_double(Discordrb::Overwrite, :overwrite)
      element = { 'id' => 1 }
      overwrites = [element]
      allow(Discordrb::Overwrite).to receive(:from_hash).and_call_original
      allow(Discordrb::Overwrite).to receive(:from_hash).with(element).and_return(overwrite)
      channel.__send__(:process_permission_overwrites, overwrites)
      expect(channel.instance_variable_get(:@permission_overwrites)[1]).to eq(overwrite)
    end
  end

  describe '#sort_after' do
    it 'calls the API' do
      allow(server).to receive(:channels).and_return([])
      allow(server).to receive(:id).and_return(double)
      expect(Discordrb::API::Server).to receive(:update_channel_positions)

      channel.sort_after
    end

    it 'only sends channels of its own type' do
      channels = Array.new(10) { |i| instance_double(described_class, "channel #{i}", type: i % 4, parent_id: nil, position: i, id: i) }
      allow(server).to receive(:channels).and_return(channels)
      allow(server).to receive(:id).and_return(double)
      non_text_channels = channels.reject { |e| e.type == 0 }

      expect(Discordrb::API::Server).to receive(:update_channel_positions)
        .with(any_args, an_array_excluding(*non_text_channels.map { |e| { id: e.id, position: instance_of(Integer) } }))
      channel.sort_after
    end

    context 'when other is not on this server' do
      it 'raises ArgumentError' do
        other = instance_double(described_class, :other, server: instance_double(Discordrb::Server, 'other server'), resolve_id: double, category?: nil, type: channel.type)
        allow(bot).to receive(:channel).and_return(other)
        expect { channel.sort_after(other) }.to raise_error(ArgumentError)
      end
    end

    context 'when other is not of Channel, NilClass, #resolve_id' do
      it 'raises TypeError' do
        expect { channel.sort_after(double) }.to raise_error(TypeError)
      end
    end

    context 'when other channel is not the same type' do
      it 'raises ArgumentError' do
        other_channel = instance_double(described_class, :other_channel, resolve_id: double, type: double, category?: nil)
        allow(bot).to receive(:channel).and_return(other_channel)
        expect { channel.sort_after(other_channel) }.to raise_error(ArgumentError)
      end
    end

    context 'when channel is in a category' do
      it 'sends parent_id' do
        category = instance_double(described_class, :category, id: 1)
        other_channel = instance_double(described_class, :other_channel, id: 2, resolve_id: double, type: channel.type, category?: nil, server: channel.server, parent: category, position: 5)
        allow(category).to receive(:children).and_return [other_channel, channel]
        allow(bot).to receive(:channel).and_return(other_channel)
        expect(Discordrb::API::Server).to receive(:update_channel_positions)
          .with(any_args, [{ id: 2, position: 0 }, { id: channel.id, position: 1, parent_id: category.id }])
        channel.sort_after(other_channel)
      end
    end

    context 'when channel is not in a category' do
      it 'sends null' do
        other_channel = instance_double(described_class, :other_channel, id: 2, resolve_id: double, type: channel.type, category?: nil, server: channel.server, parent: nil, parent_id: nil, position: 5)
        allow(server).to receive(:channels).and_return [other_channel, channel]
        allow(bot).to receive(:channel).and_return(other_channel)
        expect(Discordrb::API::Server).to receive(:update_channel_positions)
          .with(any_args, [{ id: 2, position: 0 }, { id: channel.id, position: 1, parent_id: nil }])
        channel.sort_after(other_channel)
      end
    end
  end
end
