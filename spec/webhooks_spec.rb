# frozen_string_literal: true

require 'securerandom'
require 'discordrb/webhooks'

describe Discordrb::Webhooks do
  describe Discordrb::Webhooks::Builder do
    it 'should be able to add embeds' do
      builder = Discordrb::Webhooks::Builder.new

      embed = builder.add_embed do |e|
        e.title = 'a'
        e.image = Discordrb::Webhooks::EmbedImage.new(url: 'https://example.com/image.png')
      end

      expect(builder.embeds.length).to eq 1
      expect(builder.embeds.first).to eq embed
    end
  end

  describe Discordrb::Webhooks::Embed do
    it 'should be able to have fields added' do
      embed = Discordrb::Webhooks::Embed.new

      embed.add_field(name: 'a', value: 'b', inline: true)

      expect(embed.fields.length).to eq 1
    end

    describe '#colour=' do
      it 'should accept colours in decimal format' do
        embed = Discordrb::Webhooks::Embed.new
        colour = 1234

        embed.colour = colour
        expect(embed.colour).to eq colour
      end

      it 'should raise if the colour value is too high' do
        embed = Discordrb::Webhooks::Embed.new
        colour = 100_000_000

        expect { embed.colour = colour }.to raise_error(ArgumentError)
      end

      it 'should accept colours in hex format' do
        embed = Discordrb::Webhooks::Embed.new
        colour = '162a3f'

        embed.colour = colour
        expect(embed.colour).to eq 1_452_607
      end

      it 'should accept colours in hex format with a # in front' do
        embed = Discordrb::Webhooks::Embed.new
        colour = '#162a3f'

        embed.colour = colour
        expect(embed.colour).to eq 1_452_607
      end

      it 'should accept colours as a RGB tuple' do
        embed = Discordrb::Webhooks::Embed.new
        colour = [22, 42, 63]

        embed.colour = colour
        expect(embed.colour).to eq 1_452_607
      end

      it 'should raise if a RGB tuple is of the wrong size' do
        embed = Discordrb::Webhooks::Embed.new

        expect { embed.colour = [0, 1] }.to raise_error(ArgumentError)
        expect { embed.colour = [0, 1, 2, 3] }.to raise_error(ArgumentError)
      end

      it 'should raise if a RGB tuple results in a too large value' do
        embed = Discordrb::Webhooks::Embed.new

        expect { embed.colour = [2000, 1, 2] }.to raise_error(ArgumentError)
      end
    end
  end

  describe Discordrb::Webhooks::Client do
    let(:id) { SecureRandom.bytes(8) }
    let(:token) { SecureRandom.bytes(24) }
    let(:provided_url) { instance_double(String) }

    subject { described_class.new(url: provided_url) }

    describe '#initialize' do
      it 'generates a url from id and token' do
        client = described_class.new(id: id, token: token)
        url = client.instance_variable_get(:@url)

        expect(url).to eq "https://discord.com/api/v8/webhooks/#{id}/#{token}"
      end

      it 'takes a provided url' do
        client = described_class.new(url: provided_url)
        url = client.instance_variable_get(:@url)

        expect(url).to be provided_url
      end
    end

    describe '#execute' do
      let(:json_hash) { instance_double(Hash) }
      let(:default_builder) { instance_double(Discordrb::Webhooks::Builder, to_json_hash: json_hash) }

      before do
        allow(subject).to receive(:post_json).with(any_args)
        allow(subject).to receive(:post_multipart).with(any_args)
        allow(default_builder).to receive(:file).and_return(nil)
      end

      it 'takes a default builder' do
        expect { |b| subject.execute(default_builder, &b) }.to yield_with_args(default_builder, instance_of(Discordrb::Webhooks::View))
      end

      context 'when a builder is not provided' do
        it 'creates a new builder if none is provided' do
          expect { |b| subject.execute(&b) }.to yield_with_args(
            instance_of(Discordrb::Webhooks::Builder),
            instance_of(Discordrb::Webhooks::View)
          )
        end
      end

      context 'when a file is provided' do
        it 'POSTs multipart data' do
          allow(default_builder).to receive(:file).and_return(true)

          subject.execute(default_builder)

          expect(subject).to have_received(:post_multipart).with(default_builder, any_args)
        end
      end

      context 'when a file is not provided' do
        it 'POSTs json data' do
          subject.execute(default_builder)

          expect(subject).to have_received(:post_json).with(default_builder, any_args)
        end
      end
    end

    describe '#modify' do
      let(:name) { instance_double(String) }

      before do
        allow(RestClient).to receive(:patch).with(any_args)
      end

      it 'sends a PATCH request to the URL' do
        subject.modify

        expect(RestClient).to have_received(:patch).with(provided_url, anything, content_type: :json)
      end
    end

    describe '#delete' do
      before do
        allow(RestClient).to receive(:delete).with(any_args)
      end

      it 'sends a DELETE request to the URL' do
        reason = instance_double(String)

        subject.delete(reason: reason)

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
        expect { |b| subject.edit_message(message_id, &b) }.to yield_with_args(instance_of(Discordrb::Webhooks::Builder))
      end

      it 'uses the provided builder' do
        expect { |b| subject.edit_message(message_id, builder: default_builder, &b) }.to yield_with_args(default_builder)
      end

      it 'sends a PATCH request to the message URL' do
        url = subject.instance_variable_get(:@url)

        subject.edit_message(message_id)

        expect(RestClient).to have_received(:patch).with("#{url}/messages/#{message_id}", instance_of(String), content_type: :json)
      end
    end

    describe '#delete_message' do
      let(:base_url) { 'url' }
      let(:message_id) { SecureRandom.bytes(8) }

      subject { described_class.new(url: base_url) }

      before do
        allow(RestClient).to receive(:delete).with(any_args)
      end

      it 'sends a DELETE request to the message URL' do
        subject.delete_message(message_id)

        expect(RestClient).to have_received(:delete).with("#{base_url}/messages/#{message_id}")
      end
    end

    describe '#post_json' do
      let(:builder) { Discordrb::Webhooks::Builder.new(content: 'value') }

      before do
        allow(RestClient).to receive(:post).with(any_args)
        allow(provided_url).to receive(:+).with(anything).and_return(provided_url)
      end

      it 'makes a POST request with JSON data' do
        subject.__send__(:post_json, builder, [], false)

        expect(RestClient).to have_received(:post).with(provided_url, builder.to_json_hash.merge({ components: [] }).to_json, content_type: :json)
      end

      it 'waits when wait=true' do
        subject.__send__(:post_json, builder, [], true)

        expect(provided_url).to have_received(:+).with('?wait=true')
      end
    end

    describe '#post_multipart' do
      let(:post_data) { instance_double(Hash) }
      let(:multipart_hash) { instance_double(Hash) }
      let(:builder) { instance_double(Discordrb::Webhooks::Builder, to_multipart_hash: multipart_hash) }

      before do
        allow(RestClient).to receive(:post).with(any_args)
        allow(provided_url).to receive(:+).with(anything).and_return(provided_url)
        allow(multipart_hash).to receive(:merge).with(instance_of(Hash)).and_return(post_data)
      end

      it 'makes a POST request with multipart data' do
        subject.__send__(:post_multipart, builder, [], false)

        expect(RestClient).to have_received(:post).with(provided_url, post_data)
      end

      it 'waits for a response when wait=true' do
        subject.__send__(:post_multipart, builder, [], true)

        expect(provided_url).to have_received(:+).with('?wait=true')
      end
    end

    describe '#avatarise' do
      let(:data) { SecureRandom.bytes(24) }

      it 'makes no changes if the argument does not respond to read' do
        expect(subject.__send__(:avatarise, data)).to be data
      end

      it 'returns multipart data if the argument responds to read' do
        encoded = subject.__send__(:avatarise, StringIO.new(data))
        expect(encoded).to eq "data:image/jpg;base64,#{Base64.strict_encode64(data)}"
      end
    end
  end
end
