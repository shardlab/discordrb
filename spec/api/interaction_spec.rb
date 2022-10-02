# frozen_string_literal: true

require 'securerandom'
require 'discordrb'

describe Discordrb::API::Interaction do
  let(:interaction_token) { SecureRandom.base64(200) }
  let(:interaction_id) { SecureRandom.random_number(1000) }
  let(:application_id) { SecureRandom.random_number(1000) }
  let(:content) { 'hello world' }
  let(:callback_type) { Discordrb::Interaction::CALLBACK_TYPES[:channel_message] }
  let(:file) { double(File) }

  describe '#create_interaction_response' do
    it 'sends a JSON payload with headers when file is not specified' do
      expect(Discordrb::API).to receive(:request).with(
        :interactions_iid_token_callback,
        interaction_id,
        :post,
        "#{Discordrb::API.api_base}/interactions/#{interaction_id}/#{interaction_token}/callback",
        { type: callback_type, data: { content: content } }.to_json,
        { content_type: :json }
      )

      Discordrb::API::Interaction.create_interaction_response(
        interaction_token,
        interaction_id,
        callback_type,
        'hello world'
      )
    end

    it 'sends a multipart payload when a file is specified' do
      expect(Discordrb::API).to receive(:request).with(
        :interactions_iid_token_callback,
        interaction_id,
        :post,
        "#{Discordrb::API.api_base}/interactions/#{interaction_id}/#{interaction_token}/callback",
        { file: file, payload_json: { type: callback_type, data: { content: content } }.to_json },
        nil
      )

      Discordrb::API::Interaction.create_interaction_response(
        interaction_token,
        interaction_id,
        callback_type,
        'hello world',
        nil, # tts
        nil, # embeds
        nil, # allowed_mentions
        nil, # flags
        nil, # components
        file
      )
    end
  end

  describe '#get_original_interaction_response' do
    it 'calls webhook api with correct parameters' do
      expect(Discordrb::API::Webhook).to receive(:token_get_message).with(
        interaction_id,
        application_id,
        '@original'
      )

      Discordrb::API::Interaction.get_original_interaction_response(
        interaction_id,
        application_id
      )
    end
  end

  describe '#edit_original_interaction_response' do
    it 'calls webhook api with correct parameters' do
      expect(Discordrb::API::Webhook).to receive(:token_edit_message).with(
        interaction_id,
        application_id,
        '@original',
        content,
        nil, # embeds
        nil, # allowed_mentions
        nil, # components
        file
      )

      Discordrb::API::Interaction.edit_original_interaction_response(
        interaction_id,
        application_id,
        content,
        nil, # embeds
        nil, # allowed_mentions
        nil, # components
        file
      )
    end
  end

  describe '#delete_original_interaction_response' do
    it 'calls webhook api with correct parameters' do
      expect(Discordrb::API::Webhook).to receive(:token_delete_message).with(
        interaction_token,
        application_id,
        '@original'
      )

      Discordrb::API::Interaction.delete_original_interaction_response(
        interaction_token,
        application_id
      )
    end
  end
end
