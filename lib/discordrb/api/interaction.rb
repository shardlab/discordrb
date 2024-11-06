# frozen_string_literal: true

# API calls for interactions.
module Discordrb::API::Interaction
  module_function

  CACHE_TTL = 300 # 5 minutes cache duration
  
  def cache
    @cache ||= Hash.new { |h, k| h[k] = { data: nil, timestamp: nil } }
  end

  def cached_request(cache_key, ttl = CACHE_TTL)
    cache_entry = cache[cache_key]
    current_time = Time.now.to_i

    if cache_entry[:data] && cache_entry[:timestamp] && (current_time - cache_entry[:timestamp] < ttl)
      return cache_entry[:data]
    end

    result = yield
    cache[cache_key] = { data: result, timestamp: current_time }
    result
  end

  # Respond to an interaction.
  def create_interaction_response(interaction_token, interaction_id, type, content = nil, tts = nil, embeds = nil, allowed_mentions = nil, flags = nil, components = nil)
    data = { tts: tts, content: content, embeds: embeds, allowed_mentions: allowed_mentions, flags: flags, components: components }.compact

    Discordrb::API.request(
      :interactions_iid_token_callback,
      interaction_id,
      :post,
      "#{Discordrb::API.api_base}/interactions/#{interaction_id}/#{interaction_token}/callback",
      { type: type, data: data }.to_json,
      content_type: :json
    )
  end

  # Create a response that results in a modal.
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
  def get_original_interaction_response(interaction_token, application_id)
    cache_key = "original_response:#{interaction_token}:#{application_id}"
    
    cached_request(cache_key) do
      Discordrb::API::Webhook.token_get_message(interaction_token, application_id, '@original')
    end
  end

  # Edit the original response to an interaction.
  def edit_original_interaction_response(interaction_token, application_id, content = nil, embeds = nil, allowed_mentions = nil, components = nil)
    cache_key = "original_response:#{interaction_token}:#{application_id}"
    
    result = Discordrb::API::Webhook.token_edit_message(
      interaction_token, 
      application_id, 
      '@original', 
      content, 
      embeds, 
      allowed_mentions, 
      components
    )
    
    # Invalidate cache after editing
    cache.delete(cache_key)
    result
  end

  # Delete the original response to an interaction.
  def delete_original_interaction_response(interaction_token, application_id)
    cache_key = "original_response:#{interaction_token}:#{application_id}"
    
    result = Discordrb::API::Webhook.token_delete_message(interaction_token, application_id, '@original')
    
    # Invalidate cache after deletion
    cache.delete(cache_key)
    result
  end

  # Clear the entire cache
  def clear_cache
    cache.clear
  end
end