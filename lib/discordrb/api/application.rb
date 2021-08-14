# frozen_string_literal: true

# API calls for slash commands.
module Discordrb::API::Application
  module_function

  # Get a list of global application commands.
  # https://discord.com/developers/docs/interactions/slash-commands#get-global-application-commands
  def get_global_commands(token, application_id)
    Discordrb::API.request(
      :applications_aid_commands,
      nil,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/commands",
      Authorization: token
    )
  end

  # Get a global application command by ID.
  # https://discord.com/developers/docs/interactions/slash-commands#get-global-application-command
  def get_global_command(token, application_id, command_id)
    Discordrb::API.request(
      :applications_aid_commands_cid,
      nil,
      :get,
      "#{Discordrb::API.api_base}/applications/#{application_id}/commands/#{command_id}",
      Authorization: token
    )
  end

  # Create a global application command.
  # https://discord.com/developers/docs/interactions/slash-commands#create-global-application-command
  def create_global_command(token, application_id, name, description, options = [], default_permission = nil, type = 1)
    Discordrb::API.request(
      :applications_aid_commands,
      nil,
      :post,
      "#{Discordrb::API.api_base}/applications/#{application_id}/commands",
      { name: name, description: description, options: options, default_permission: default_permission, type: type }.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Edit a global application command.
  # https://discord.com/developers/docs/interactions/slash-commands#edit-global-application-command
  def edit_global_command(token, application_id, command_id, name = nil, description = nil, options = nil, default_permission = nil, type = 1)
    Discordrb::API.request(
      :applications_aid_commands_cid,
      nil,
      :patch,
      "#{Discordrb::API.api_base}/applications/#{application_id}/commands/#{command_id}",
      { name: name, description: description, options: options, default_permission: default_permission, type: type }.compact.to_json,
      Authorization: token,
      content_type: :json
    )
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
  def create_guild_command(token, application_id, guild_id, name, description, options = nil, default_permission = nil, type = 1)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands,
      guild_id,
      :post,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands",
      { name: name, description: description, options: options, default_permission: default_permission, type: type }.to_json,
      Authorization: token,
      content_type: :json
    )
  end

  # Edit an application command for a guild.
  # https://discord.com/developers/docs/interactions/slash-commands#edit-guild-application-command
  def edit_guild_command(token, application_id, guild_id, command_id, name = nil, description = nil, options = nil, default_permission = nil, type = 1)
    Discordrb::API.request(
      :applications_aid_guilds_gid_commands_cid,
      guild_id,
      :patch,
      "#{Discordrb::API.api_base}/applications/#{application_id}/guilds/#{guild_id}/commands/#{command_id}",
      { name: name, description: description, options: options, default_permission: default_permission, type: type }.compact.to_json,
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
