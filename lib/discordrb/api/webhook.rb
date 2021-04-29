# frozen_string_literal: true

# API calls for Webhook object
module Discordrb::API::Webhook
  module_function

  # Get a webhook
  # https://discord.com/developers/docs/resources/webhook#get-webhook
  def webhook(token, webhook_id)
    Discordrb::API.request(
      :webhooks_wid,
      nil,
      :get,
      "#{Discordrb::API.api_base}/webhooks/#{webhook_id}",
      Authorization: token
    )
  end

  # Get a webhook via webhook token
  # https://discord.com/developers/docs/resources/webhook#get-webhook-with-token
  def token_webhook(webhook_token, webhook_id)
    Discordrb::API.request(
      :webhooks_wid,
      nil,
      :get,
      "#{Discordrb::API.api_base}/webhooks/#{webhook_id}/#{webhook_token}"
    )
  end

  # Update a webhook
  # https://discord.com/developers/docs/resources/webhook#modify-webhook
  def update_webhook(token, webhook_id, data, reason = nil)
    Discordrb::API.request(
      :webhooks_wid,
      webhook_id,
      :patch,
      "#{Discordrb::API.api_base}/webhooks/#{webhook_id}",
      data.to_json,
      Authorization: token,
      content_type: :json,
      'X-Audit-Log-Reason': reason
    )
  end

  # Update a webhook via webhook token
  # https://discord.com/developers/docs/resources/webhook#modify-webhook-with-token
  def token_update_webhook(webhook_token, webhook_id, data, reason = nil)
    Discordrb::API.request(
      :webhooks_wid,
      webhook_id,
      :patch,
      "#{Discordrb::API.api_base}/webhooks/#{webhook_id}/#{webhook_token}",
      data.to_json,
      content_type: :json,
      'X-Audit-Log-Reason': reason
    )
  end

  # Deletes a webhook
  # https://discord.com/developers/docs/resources/webhook#delete-webhook
  def delete_webhook(token, webhook_id, reason = nil)
    Discordrb::API.request(
      :webhooks_wid,
      webhook_id,
      :delete,
      "#{Discordrb::API.api_base}/webhooks/#{webhook_id}",
      Authorization: token,
      'X-Audit-Log-Reason': reason
    )
  end

  # Deletes a webhook via webhook token
  # https://discord.com/developers/docs/resources/webhook#delete-webhook-with-token
  def token_delete_webhook(webhook_token, webhook_id, reason = nil)
    Discordrb::API.request(
      :webhooks_wid,
      webhook_id,
      :delete,
      "#{Discordrb::API.api_base}/webhooks/#{webhook_id}/#{webhook_token}",
      'X-Audit-Log-Reason': reason
    )
  end

  # Edit a message created by a specific webhook.
  # https://discord.com/developers/docs/resources/webhook#edit-webhook-message
  def edit_webhook_message(webhook_token, webhook_id, message_id, content: nil, embeds: nil, allowed_mentions: nil)
    Discordrb::API.request(
      :webhooks_wid,
      webhook_id,
      :patch,
      "#{Discordrb::API.api_base}/webhooks/#{webhook_id}/#{webhook_token}/messages/#{message_id}",
      { content: content, embeds: embeds, allowed_mentions: allowed_mentions }.to_json,
      content_type: :json
    )
  end

  # Delete a message created by a specific webhook.
  # https://discord.com/developers/docs/resources/webhook#delete-webhook-message
  def delete_webhook_message(webhook_token, webhook_id, message_id)
    Discordrb::API.request(
      :webhooks_id,
      webhook_id,
      :delete,
      "#{Discordrb::API.api_base}/webhooks/#{webhook_id}/#{webhook_token}/messages/#{message_id}",
      {}
    )
  end

  # Respond to an interaction.
  # https://discord.com/developers/docs/interactions/slash-commands#create-interaction-response
  def create_interaction_response(interaction_token, interaction_id, type, tts: nil, content: nil, embeds: nil, allowed_mentions: nil, flags: nil)
    data = { tts: tts, content: content, embeds: embeds, allowed_mentions: allowed_mentions, flags: flags }.compact
    data = nil if data.empty?

    Discordrb::API.request(
      :interactions_iid_token_callback,
      interaction_id,
      :post,
      "#{Discordrb::API.api_base}/interactions/#{interaction_id}/#{interaction_token}/callback",
      { type: type, data: data }.to_json,
      content_type: :json
    )
  end

  # Edit the original response to an interaction.
  # https://discord.com/developers/docs/interactions/slash-commands#edit-original-interaction-response
  def edit_original_interaction_response(interaction_token, application_id, content: nil, embeds: nil, allowed_mentions: nil)
    edit_webhook_message(interaction_token, application_id, '@original', content: content, embeds: embeds, allowed_mentions: allowed_mentions)
  end

  # Delete the original response to an interaction.
  # https://discord.com/developers/docs/interactions/slash-commands#delete-original-interaction-response
  def delete_original_interaction_response(interaction_token, application_id)
    delete_webhook_message(interaction_token, application_id, '@original')
  end
end
