# frozen_string_literal: true

# API calls for invites.
module Discordrb::API::Invite
  module_function

  # Resolve an invite
  # https://discord.com/developers/docs/resources/invite#get-invite
  def resolve(token, invite_code, counts = true)
    Discordrb::API.request(
      :invite_code,
      nil,
      :get,
      "#{Discordrb::API.api_base}/invites/#{invite_code}#{'?with_counts=true' if counts}",
      Authorization: token
    )
  end

  # Delete an invite by code
  # https://discord.com/developers/docs/resources/invite#delete-invite
  def delete(token, code, reason = nil)
    Discordrb::API.request(
      :invites_code,
      nil,
      :delete,
      "#{Discordrb::API.api_base}/invites/#{code}",
      Authorization: token,
      'X-Audit-Log-Reason': reason
    )
  end

  # Get the target users for an invite.
  # https://discord.com/developers/docs/resources/invite#get-target-users
  def get_target_users(token, code)
    Discordrb::API.request(
      :invites_code_target_users,
      nil,
      :get,
      "#{Discordrb::API.api_base}/invites/#{code}/target-users",
      Authorization: token
    )
  end

  # Update the target users for an invite.
  # https://discord.com/developers/docs/resources/invite#update-target-users
  def update_target_users(token, code, target_users_file:)
    Discordrb::API.request(
      :invites_code_target_users,
      nil,
      :put,
      "#{Discordrb::API.api_base}/invites/#{code}/target-users",
      { target_users_file: },
      Authorization: token
    )
  end

  # Get the target users job status for an invite.
  # https://discord.com/developers/docs/resources/invite#get-target-users-job-status
  def get_target_users_job_status(token, code)
    Discordrb::API.request(
      :invites_code_target_users,
      nil,
      :get,
      "#{Discordrb::API.api_base}/invites/#{code}/target-users/job-status",
      Authorization: token
    )
  end
end
