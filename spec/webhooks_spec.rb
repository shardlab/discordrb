# frozen_string_literal: true

require 'base64'
require 'securerandom'
require 'discordrb/webhooks'

describe Discordrb::Webhooks do
  describe Discordrb::Webhooks::Builder do
    it 'is able to add embeds' do
      builder = described_class.new

      embed = builder.add_embed do |e|
        e.title = 'a'
        e.image = Discordrb::Webhooks::EmbedImage.new(url: 'https://example.com/image.png')
      end

      expect(builder.embeds.first).to eq embed
    end
  end

  describe Discordrb::Webhooks::Embed do
    it 'is able to have fields added' do
      embed = described_class.new

      embed.add_field(name: 'a', value: 'b', inline: true)

      expect(embed.fields.length).to eq 1
    end

    describe '#colour=' do
      it 'accepts colours in decimal format' do
        embed = described_class.new
        colour = 1234

        embed.colour = colour
        expect(embed.colour).to eq colour
      end

      it 'raises if the colour value is too high' do
        embed = described_class.new
        colour = 100_000_000

        expect { embed.colour = colour }.to raise_error(ArgumentError)
      end

      it 'accepts colours in hex format' do
        embed = described_class.new
        colour = '162a3f'

        embed.colour = colour
        expect(embed.colour).to eq 1_452_607
      end

      it 'accepts colours in hex format with a # in front' do
        embed = described_class.new
        colour = '#162a3f'

        embed.colour = colour
        expect(embed.colour).to eq 1_452_607
      end

      it 'accepts colours as an RGB tuple' do
        embed = described_class.new
        colour = [22, 42, 63]

        embed.colour = colour
        expect(embed.colour).to eq 1_452_607
      end

      shared_examples 'should raise if a RGB tuple is of the wrong size' do |tuple|
        it "raises an error for tuple #{tuple}" do
          embed = described_class.new

          expect { embed.colour = tuple }.to raise_error(ArgumentError)
        end
      end

      include_examples 'should raise if a RGB tuple is of the wrong size', [0, 1]
      include_examples 'should raise if a RGB tuple is of the wrong size', [0, 1, 2, 3]

      it 'raises if an RGB tuple results in a too large value' do
        embed = described_class.new

        expect { embed.colour = [2000, 1, 2] }.to raise_error(ArgumentError)
      end
    end
  end

  describe Discordrb::Webhooks::Client do
    subject(:client) { described_class.new(url: provided_url) }

    let(:provided_url) { instance_double(String, 'provided url') }

    describe '#initialize' do
      it 'generates a url from id and token' do
        id = SecureRandom.bytes(8)
        token = SecureRandom.bytes(24)
        client = described_class.new(id: id, token: token)
        url = client.instance_variable_get(:@url)

        expect(url).to eq "https://discord.com/api/v9/webhooks/#{id}/#{token}"
      end

      it 'takes a provided url' do
        url = client.instance_variable_get(:@url)

        expect(url).to be provided_url
      end
    end

    describe '#execute' do
      let(:json_hash) { instance_double(Hash) }
      let(:default_builder) { instance_double(Discordrb::Webhooks::Builder, to_json_hash: json_hash) }

      before do
        allow(client).to receive_messages(post_json: nil, post_multipart: nil)
        allow(default_builder).to receive(:file)
      end

      it 'takes a default builder' do
        expect { |b| client.execute(default_builder, &b) }.to yield_with_args(default_builder, instance_of(Discordrb::Webhooks::View))
      end

      it 'creates a new builder if none is provided' do
        expect { |b| client.execute(&b) }.to yield_with_args(
          instance_of(Discordrb::Webhooks::Builder),
          instance_of(Discordrb::Webhooks::View)
        )
      end

      it 'POSTs multipart data when a file is provided' do
        allow(default_builder).to receive(:file).and_return(true)

        client.execute(default_builder)

        expect(client).to have_received(:post_multipart).with(default_builder, any_args)
      end

      it 'POSTs json data when a file is not provided' do
        client.execute(default_builder)

        expect(client).to have_received(:post_json).with(default_builder, any_args)
      end
    end

    describe '#modify' do
      let(:name) { instance_double(String) }

      before do
        allow(RestClient).to receive(:patch).with(any_args)
      end

      it 'sends a PATCH request to the URL' do
        client.modify

        expect(RestClient).to have_received(:patch).with(provided_url, anything, content_type: :json)
      end
    end

    describe '#delete' do
      before do
        allow(RestClient).to receive(:delete).with(any_args)
      end

      it 'sends a DELETE request to the URL' do
        reason = instance_double(String)

        client.delete(reason: reason)

        expect(RestClient).to have_received(:delete).with(provided_url, 'X-Audit-Log-Reason': reason)
      end
    end

    describe '#edit_message' do
      let(:message_id) { SecureRandom.bytes(8) }
      let(:json_hash) { {} }
      let(:default_builder) { instance_double(Discordrb::Webhooks::Builder, to_json_hash: json_hash) }

      before do
        allow(RestClient).to receive(:patch).with(any_args)
      end

      it 'creates a new builder if one is not provided' do
        expect { |b| client.edit_message(message_id, &b) }.to yield_with_args(instance_of(Discordrb::Webhooks::Builder))
      end

      it 'uses the provided builder' do
        expect { |b| client.edit_message(message_id, builder: default_builder, &b) }.to yield_with_args(default_builder)
      end

      it 'sends a PATCH request to the message URL' do
        url = client.instance_variable_get(:@url)

        client.edit_message(message_id)

        expect(RestClient).to have_received(:patch).with("#{url}/messages/#{message_id}", instance_of(String), content_type: :json)
      end
    end

    describe '#delete_message' do
      # subject(:client) { described_class.new(url: base_url) }

      let(:message_id) { SecureRandom.bytes(8) }

      before do
        allow(RestClient).to receive(:delete).with(any_args)
      end

      it 'sends a DELETE request to the message URL' do
        client.delete_message(message_id)

        expect(RestClient).to have_received(:delete).with("#{provided_url}/messages/#{message_id}")
      end
    end

    describe '#post_json' do
      let(:builder) { Discordrb::Webhooks::Builder.new(content: 'value') }

      before do
        allow(RestClient).to receive(:post).with(any_args)
        allow(provided_url).to receive(:+).with(anything).and_return(provided_url)
      end

      it 'makes a POST request with JSON data' do
        client.__send__(:post_json, builder, [], false)

        expect(RestClient).to have_received(:post).with(provided_url, builder.to_json_hash.merge({ components: [] }).to_json, content_type: :json)
      end

      it 'waits when wait=true' do
        client.__send__(:post_json, builder, [], true)

        expect(provided_url).to have_received(:+).with('?wait=true')
      end
    end

    describe '#post_multipart' do
      let(:multipart_hash) { instance_double(Hash) }
      let(:builder) { instance_double(Discordrb::Webhooks::Builder, to_multipart_hash: multipart_hash) }

      before do
        allow(RestClient).to receive(:post).with(any_args)
        allow(provided_url).to receive(:+).with(anything).and_return(provided_url)
      end

      it 'makes a POST request with multipart data' do
        post_data = instance_double(Hash)
        allow(multipart_hash).to receive(:merge).with(instance_of(Hash)).and_return(post_data)
        client.__send__(:post_multipart, builder, [], false)

        expect(RestClient).to have_received(:post).with(provided_url, post_data)
      end

      it 'waits for a response when wait=true' do
        allow(multipart_hash).to receive(:merge)
        client.__send__(:post_multipart, builder, [], true)

        expect(provided_url).to have_received(:+).with('?wait=true')
      end
    end

    describe '#avatarise' do
      let(:data) { SecureRandom.bytes(24) }

      it 'makes no changes if the argument does not respond to read' do
        expect(client.__send__(:avatarise, data)).to be data
      end

      it 'returns multipart data if the argument responds to read' do
        encoded = client.__send__(:avatarise, StringIO.new(data))
        expect(encoded).to eq "data:image/jpg;base64,#{Base64.strict_encode64(data)}"
      end
    end
  end
end
