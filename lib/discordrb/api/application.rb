# frozen_string_literal: true

module Discordrb::API::Application
  module_function

  # Cache and rate limit settings
  CACHE_TTL = 300 # seconds
  RATE_LIMIT = 50 # requests per second
  
  # In-memory cache implementation
  @cache = {}
  @last_requests = {}
  @request_counts = {}

  def self.cache_key(method, *args)
    "#{method}:#{args.join(':')}"
  end

  def self.cached_request(method, *args)
    key = cache_key(method, *args)
    current_time = Time.now.to_f

    # Check cache
    if @cache[key] && current_time - @cache[key][:timestamp] < CACHE_TTL
      return @cache[key][:data]
    end

    # Rate limit handling
    handle_rate_limit(method)

    # Execute request and cache result
    result = yield
    @cache[key] = {
      data: result,
      timestamp: current_time
    }
    
    result
  end

  def self.handle_rate_limit(method)
    current_time = Time.now.to_f
    
    # Reset counter if window has passed
    if @last_requests[method].nil? || current_time - @last_requests[method] >= 1
      @request_counts[method] = 0
      @last_requests[method] = current_time
    end

    @request_counts[method] ||= 0
    @request_counts[method] += 1

    # Sleep if rate limit is exceeded
    if @request_counts[method] > RATE_LIMIT
      sleep_time = (1 - (current_time - @last_requests[method]))
      sleep(sleep_time) if sleep_time.positive?
      @request_counts[method] = 0
      @last_requests[method] = Time.now.to_f
    end
  end

  # Modified API methods using caching
  def get_global_commands(token, application_id)
    cached_request(__method__, application_id) do
      Discordrb::API.request(
        :applications_aid_commands,
        nil,
        :get,
        "#{Discordrb::API.api_base}/applications/#{application_id}/commands",
        Authorization: token
      )
    end
  end

  def get_global_command(token, application_id, command_id)
    cached_request(__method__, application_id, command_id) do
      Discordrb::API.request(
        :applications_aid_commands_cid,
        nil,
        :get,
        "#{Discordrb::API.api_base}/applications/#{application_id}/commands/#{command_id}",
        Authorization: token
      )
    end
  end

  # Write methods (no caching, only rate limiting)
  def create_global_command(token, application_id, name, description, options = [], default_permission = nil, type = 1, default_member_permissions = nil, contexts = nil)
    handle_rate_limit(__method__)
    Discordrb::API.request(
      :applications_aid_commands,
      nil,
      :post,
      "#{Discordrb::API.api_base}/applications/#{application_id}/commands",
      { name: name, description: description, options: options, default_permission: default_permission, type: type, default_member_permissions: default_member_permissions, contexts: contexts }.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Cache invalidation helper
  def self.invalidate_cache!
    @cache.clear
  end

  # Add cache invalidation for write operations
  def self.invalidate_command_cache(application_id)
    @cache.delete_if { |k, _| k.include?(application_id.to_s) }
  end

  # Modified write methods with cache invalidation
  def edit_global_command(token, application_id, command_id, name = nil, description = nil, options = nil, default_permission = nil, type = 1, default_member_permissions = nil, contexts = nil)
    handle_rate_limit(__method__)
    result = Discordrb::API.request(
      :applications_aid_commands_cid,
      nil,
      :patch,
      "#{Discordrb::API.api_base}/applications/#{application_id}/commands/#{command_id}",
      { name: name, description: description, options: options, default_permission: default_permission, type: type, default_member_permissions: default_member_permissions, contexts: contexts }.compact.to_json,
      Authorization: token,
      content_type: :json
    )
    self.class.invalidate_command_cache(application_id)
    result
  end

  # Delete a global application command.
  # https://discord.com/developers/docs/interactions/slash-commands#delete-global-application-command
  def delete_global_command(token, application_id, command_id)
    Discordrb::API.request(
      :applications_aid_commands_cid,
      nil,
      :delete,
      "#{Discordrb::API.api_base}/applications/#{application_id}/commands/#{command_id}",
      Authorization: token
    )
  end

  # Set global application commands in bulk.
  # https://discord.com/developers/docs/interactions/slash-commands#bulk-overwrite-global-application-commands
  def bulk_overwrite_global_commands(token, application_id, commands)
    Discordrb::API.request(
      :applications_aid_commands,
      nil,
      :put,
      "#{Discordrb::API.api_base}/applications/#{application_id}/commands",
      commands.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Get a guild's commands for an application.
  # https://discord.com/developers/docs/interactions/slash-commands#get-guild-application-commands
  def get_guild_commands(token, application_id, guild_id)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands,
      guild_id,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands",
      Authorization: token
    )
  end

  # Get a guild command by ID.
  # https://discord.com/developers/docs/interactions/slash-commands#get-guild-application-command
  def get_guild_command(token, application_id, guild_id, command_id)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands_cid,
      guild_id,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}",
      Authorization: token
    )
  end

  # Create an application command for a guild.
  # https://discord.com/developers/docs/interactions/slash-commands#create-guild-application-command
  def create_guild_command(token, application_id, guild_id, name, description, options = nil, default_permission = nil, type = 1, default_member_permissions = nil, contexts = nil)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands,
      guild_id,
      :post,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands",
      { name: name, description: description, options: options, default_permission: default_permission, type: type, default_member_permissions: default_member_permissions, contexts: contexts }.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Edit an application command for a guild.
  # https://discord.com/developers/docs/interactions/slash-commands#edit-guild-application-command
  def edit_guild_command(token, application_id, guild_id, command_id, name = nil, description = nil, options = nil, default_permission = nil, type = 1, default_member_permissions = nil, contexts = nil)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands_cid,
      guild_id,
      :patch,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}",
      { name: name, description: description, options: options, default_permission: default_permission, type: type, default_member_permissions: default_member_permissions, contexts: contexts }.compact.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Delete an application command for a guild.
  # https://discord.com/developers/docs/interactions/slash-commands#delete-guild-application-command
  def delete_guild_command(token, application_id, guild_id, command_id)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands_cid,
      guild_id,
      :delete,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}",
      Authorization: token
    )
  end

  # Set guild commands in bulk.
  # https://discord.com/developers/docs/interactions/slash-commands#bulk-overwrite-guild-application-commands
  def bulk_overwrite_guild_commands(token, application_id, guild_id, commands)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands,
      guild_id,
      :put,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands",
      commands.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Get the permissions for a specific guild command.
  # https://discord.com/developers/docs/interactions/slash-commands#get-application-command-permissions
  def get_guild_command_permissions(token, application_id, guild_id)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands_permissions,
      guild_id,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands/permissions",
      Authorization: token
    )
  end

  # Edit the permissions for a specific guild command.
  # https://discord.com/developers/docs/interactions/slash-commands#edit-application-command-permissions
  def edit_guild_command_permissions(token, application_id, guild_id, command_id, permissions)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands_cid_permissions,
      guild_id,
      :put,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}/permissions",
      { permissions: permissions }.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Edit permissions for all commands in a guild.
  # https://discord.com/developers/docs/interactions/slash-commands#batch-edit-application-command-permissions
  def batch_edit_command_permissions(token, application_id, guild_id, permissions)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands_cid_permissions,
      guild_id,
      :put,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands/permissions",
      permissions.to_json,
      Authorization: token,
      content_type: :json
    )
  end
end
