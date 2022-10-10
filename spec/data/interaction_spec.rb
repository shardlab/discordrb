# frozen_string_literal: true

require 'securerandom'
require 'discordrb'

describe Discordrb::Interaction do
  let(:guild_id) { SecureRandom.random_number(200) }
  let(:channel_id) { SecureRandom.random_number(200) }
  let(:interaction_token) { SecureRandom.base64(200) }
  let(:interaction_id) { SecureRandom.random_number(1000) }
  let(:application_id) { SecureRandom.random_number(1000) }
  let(:content) { 'hello world' }
  let(:file) { double(File) }
  let(:attachments) { [double(File), double(File)] }
  let(:user) { double(Discordrb::Member) }
  let(:bot) do
    bot = double('bot')
    allow(bot).to receive(:ensure_user).with(any_args).and_return(user)
    bot
  end
  let(:interaction_data) do
    {
      'id' => interaction_id,
      'application_id' => application_id,
      'type' => -1,
      'message' => nil,
      'data' => {},
      'server_id' => guild_id,
      'channel_id' => channel_id,
      'user' => double,
      'token' => interaction_token,
      'version' => 1
    }
  end
  let(:message_resolve_id) { SecureRandom.random_number(1000) }
  let(:message) do
    message = double('message')
    allow(message).to receive(:resolve_id).with(any_args).and_return(message_resolve_id)
    message
  end

  subject(:interaction) do
    described_class.new(interaction_data, bot)
  end

  before(:each) do
    allow(Discordrb::Interactions::Message).to receive(:new).with(any_args).and_return(nil)
  end

  describe '#respond' do
    let(:callback_type) { Discordrb::Interaction::CALLBACK_TYPES[:channel_message] }

    it 'calls interaction api with correct parameters' do
      expect(Discordrb::API::Interaction).to receive(:create_interaction_response).with(
        interaction_token,
        interaction_id,
        callback_type,
        content,
        nil, # tts
        [], # embeds,
        nil, # allowed_mentions
        0, # flags
        [], # components
        nil # attachments
      ).and_return('null')

      interaction.respond(content: content)
    end

    it 'calls interaction api with correct parameters when attachments are added to builder' do
      expect(Discordrb::API::Interaction).to receive(:create_interaction_response).with(
        interaction_token,
        interaction_id,
        callback_type,
        content,
        nil, # tts
        nil, # embeds,
        nil, # allowed_mentions
        0, # flags
        [], # components
        attachments
      ).and_return('null')

      interaction.respond(content: content) do |builder|
        builder.attachments = attachments
      end
    end
  end

  describe '#update_message' do
    let(:callback_type) { Discordrb::Interaction::CALLBACK_TYPES[:update_message] }

    it 'calls interaction api with correct parameters' do
      expect(Discordrb::API::Interaction).to receive(:create_interaction_response).with(
        interaction_token,
        interaction_id,
        callback_type,
        content,
        nil, # tts
        [], # embeds,
        nil, # allowed_mentions
        0, # flags
        [], # components
        nil # attachments
      ).and_return('null')

      interaction.update_message(content: content)
    end

    it 'calls interaction api with correct parameters when attachments are added to builder' do
      expect(Discordrb::API::Interaction).to receive(:create_interaction_response).with(
        interaction_token,
        interaction_id,
        callback_type,
        content,
        nil, # tts
        nil, # embeds,
        nil, # allowed_mentions
        0, # flags
        [], # components
        attachments
      ).and_return('null')

      interaction.update_message(content: content) do |builder|
        builder.attachments = attachments
      end
    end
  end

  describe '#edit_response' do
    it 'calls interaction api with correct parameters' do
      expect(Discordrb::API::Interaction).to receive(:edit_original_interaction_response).with(
        interaction_token,
        application_id,
        content,
        [], # embeds,
        nil, # allowed_mentions
        [], # components
        nil # attachments
      ).and_return('null')

      interaction.edit_response(content: content)
    end

    it 'calls interaction api with correct parameters when attachments are added to builder' do
      expect(Discordrb::API::Interaction).to receive(:edit_original_interaction_response).with(
        interaction_token,
        application_id,
        content,
        nil, # embeds,
        nil, # allowed_mentions
        [], # components
        attachments # attachments
      ).and_return('null')

      interaction.edit_response(content: content) do |builder|
        builder.attachments = attachments
      end
    end
  end

  describe '#send_message' do
    it 'calls webhook api with correct parameters' do
      expect(Discordrb::API::Webhook).to receive(:token_execute_webhook).with(
        interaction_token,
        application_id,
        true, # wait
        content,
        nil, # username
        nil, # avatar_url
        false, # tts
        nil, # file
        [], # embeds
        nil, # allowed_mentions
        0, # flags
        [], # components
        nil # attachments
      ).and_return('null')

      interaction.send_message(content: content)
    end

    # this test case is for deprecated behavior
    it 'calls webhook api with correct parameters when file is added to builder' do
      expect(Discordrb::API::Webhook).to receive(:token_execute_webhook).with(
        interaction_token,
        application_id,
        true, # wait
        content,
        nil, # username
        nil, # avatar_url
        false, # tts
        file, # file
        nil, # embeds
        nil, # allowed_mentions
        0, # flags
        [], # components
        nil # attachments
      ).and_return('null')

      interaction.send_message(content: content) do |builder|
        builder.file = file
      end
    end

    it 'calls webhook api with correct parameters when attachments are added to builder' do
      expect(Discordrb::API::Webhook).to receive(:token_execute_webhook).with(
        interaction_token,
        application_id,
        true, # wait
        content,
        nil, # username
        nil, # avatar_url
        false, # tts
        nil, # file (deprecated)
        nil, # embeds
        nil, # allowed_mentions
        0, # flags
        [], # components
        attachments
      ).and_return('null')

      interaction.send_message(content: content) do |builder|
        builder.attachments = attachments
      end
    end
  end

  describe '#edit_message' do
    it 'calls webhook api with correct parameters' do
      expect(Discordrb::API::Webhook).to receive(:token_edit_message).with(
        interaction_token,
        application_id,
        message_resolve_id,
        content,
        [], # embeds
        nil, # allowed_mentions
        [], # components
        nil # attachments
      ).and_return('null')

      interaction.edit_message(message, content: content)
    end

    it 'calls webhook api with correct parameters when attachments are added to builder' do
      expect(Discordrb::API::Webhook).to receive(:token_edit_message).with(
        interaction_token,
        application_id,
        message_resolve_id,
        content,
        nil, # embeds
        nil, # allowed_mentions
        [], # components
        attachments
      ).and_return('null')

      interaction.edit_message(message, content: content) do |builder|
        builder.attachments = attachments
      end
    end
  end

  describe '#delete_message' do
    it 'calls webhook api with correct parameters' do
      expect(Discordrb::API::Webhook).to receive(:token_delete_message).with(
        interaction_token,
        application_id,
        message_resolve_id
      )

      interaction.delete_message(message)
    end
  end
end
