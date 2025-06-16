# frozen_string_literal: true

# API calls for interactions.
module Discordrb::API::Interaction
  module_function

  # Respond to an interaction.
  # https://discord.com/developers/docs/interactions/slash-commands#create-interaction-response
  def create_interaction_response(interaction_token, interaction_id, type, content = nil, tts = nil, embeds = nil, allowed_mentions = nil, flags = nil, components = nil, attachments = nil, choices = nil)
    body = { tts: tts, content: content, embeds: embeds, allowed_mentions: allowed_mentions, flags: flags, components: components, choices: choices }.compact

    body = if attachments
             files = [*0...attachments.size].zip(attachments).to_h
             { **files, payload_json: { type: type, data: body }.to_json }
           else
             { type: type, data: body }.to_json
           end

    headers = { content_type: :json } unless attachments

    Discordrb::API.request(
      :interactions_iid_token_callback,
      interaction_id,
      :post,
      "#{Discordrb::API.api_base}/interactions/#{interaction_id}/#{interaction_token}/callback",
      body,
      headers
    )
  end

  # Create a response that results in a modal.
  # https://discord.com/developers/docs/interactions/slash-commands#create-interaction-response
  def create_interaction_modal_response(interaction_token, interaction_id, custom_id, title, components)
    data = { custom_id: custom_id, title: title, components: components.to_a }.compact

    Discordrb::API.request(
      :interactions_iid_token_callback,
      interaction_id,
      :post,
      "#{Discordrb::API.api_base}/interactions/#{interaction_id}/#{interaction_token}/callback",
      { type: 9, data: data }.to_json,
      content_type: :json
    )
  end

  # Get the original response to an interaction.
  # https://discord.com/developers/docs/interactions/slash-commands#get-original-interaction-response
  def get_original_interaction_response(interaction_token, application_id)
    Discordrb::API::Webhook.token_get_message(interaction_token, application_id, '@original')
  end

  # Edit the original response to an interaction.
  # https://discord.com/developers/docs/interactions/slash-commands#edit-original-interaction-response
  def edit_original_interaction_response(interaction_token, application_id, content = nil, embeds = nil, allowed_mentions = nil, components = nil, attachments = nil, flags = nil)
    Discordrb::API::Webhook.token_edit_message(interaction_token, application_id, '@original', content, embeds, allowed_mentions, components, attachments, flags)
  end

  # Delete the original response to an interaction.
  # https://discord.com/developers/docs/interactions/slash-commands#delete-original-interaction-response
  def delete_original_interaction_response(interaction_token, application_id)
    Discordrb::API::Webhook.token_delete_message(interaction_token, application_id, '@original')
  end
end
