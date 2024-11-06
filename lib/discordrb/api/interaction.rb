# frozen_string_literal: true

module Discordrb::API::Interaction
  module_function

  CACHE_TTL = 300 # Cache TTL in seconds
  RATE_LIMIT = 50 # Requests per second

  @cache = {}
  @last_requests = {}
  @request_counts = {}

  def self.cache_key(method, *args)
    "#{method}:#{args.join(':')}"
  end

  def self.cached_request(method, *args)
    key = cache_key(method, *args)
    current_time = Time.now.to_f

    if @cache[key] && current_time - @cache[key][:timestamp] < CACHE_TTL
      return @cache[key][:data]
    end

    handle_rate_limit(method)

    result = yield
    @cache[key] = {
      data: result,
      timestamp: current_time
    }
    
    result
  end

  def self.handle_rate_limit(method)
    current_time = Time.now.to_f
    
    if @last_requests[method].nil? || current_time - @last_requests[method] >= 1
      @request_counts[method] = 0
      @last_requests[method] = current_time
    end

    @request_counts[method] ||= 0
    @request_counts[method] += 1

    if @request_counts[method] > RATE_LIMIT
      sleep_time = (1 - (current_time - @last_requests[method]))
      sleep(sleep_time) if sleep_time.positive?
      @request_counts[method] = 0
      @last_requests[method] = Time.now.to_f
    end
  end

  def self.invalidate_cache!
    @cache.clear
  end

  # API methods

  def create_interaction_response(interaction_token, interaction_id, type, content = nil, tts = nil, embeds = nil, allowed_mentions = nil, flags = nil, components = nil)
    handle_rate_limit(__method__)
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

  def create_interaction_modal_response(interaction_token, interaction_id, custom_id, title, components)
    handle_rate_limit(__method__)
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

  def get_original_interaction_response(interaction_token, application_id)
    cached_request(__method__, interaction_token, application_id) do
      Discordrb::API::Webhook.token_get_message(interaction_token, application_id, '@original')
    end
  end

  def edit_original_interaction_response(interaction_token, application_id, content = nil, embeds = nil, allowed_mentions = nil, components = nil)
    handle_rate_limit(__method__)
    result = Discordrb::API::Webhook.token_edit_message(interaction_token, application_id, '@original', content, embeds, allowed_mentions, components)
    invalidate_cache!
    result
  end

  def delete_original_interaction_response(interaction_token, application_id)
    handle_rate_limit(__method__)
    result = Discordrb::API::Webhook.token_delete_message(interaction_token, application_id, '@original')
    invalidate_cache!
    result
  end
end