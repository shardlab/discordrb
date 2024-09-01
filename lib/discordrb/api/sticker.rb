# frozen_string_literal: true

# API calls for stickers
module Discordrb::API::Sticker
  module_function

  # Return a single sticker object given the ID.
  # https://discord.com/developers/docs/resources/sticker#get-sticker
  def resolve_sticker(token, sticker_id)
    Discordrb::API.request(
      :stickers_sid,
      :sticker_id,
      :get,
      "#{Discordrb::API.api_base}/guilds/stickers/#{sticker_id}",
      Authorization: token
    )
  end

  # Get a list of avalible sticker packs.
  # https://discord.com/developers/docs/resources/sticker#list-sticker-packs
  def available_packs(token)
    Discordrb::API.request(
      :get,
      "#{Discordrb::API.api_base}/sticker-packs",
      Authorization: token
    )
  end

  # Get a sticker pack object given its ID.
  # https://discord.com/developers/docs/resources/sticker#get-sticker-pack
  def resolve_pack(token, pack_id)
    Discordrb::API.request(
      :get,
      "#{Discordrb::API.api_base}/sticker-packs/#{pack_id}",
      Authorization: token
    )
  end

  # Adds a custom sticker to a guild.
  # https://discord.com/developers/docs/resources/sticker#create-guild-sticker
  def add_sticker(token, server_id, file, name, description, tags, reason = nil)
    Discordrb::API.request(
      :guilds_sid_stickers,
      :server_id,
      :post,
      "#{Discordrb::API.api_base}/guilds/#{server_id}/stickers",
      { name: name, description: description, tags: tags, file: file },
      { multipart: true, Authorization: token, 'X-Audit-Log-Reason': reason }
    )
  end

  # Changes a sticker's name, description, or tags.
  # https://discord.com/developers/docs/resources/sticker#modify-guild-sticker
  def edit_sticker(token, server_id, sticker_id, name, description, tags, reason = nil)
    Discordrb::API.request(
      :guilds_sid_stickers_eid,
      server_id,
      :patch,
      "#{Discordrb::API.api_base}/guilds/#{server_id}/stickers/#{sticker_id}",
      { name: name, description: description, tags: tags }.to_json,
      Authorization: token,
      content_type: :json,
      'X-Audit-Log-Reason': reason
    )
  end

  # Deletes a custom sticker from a guild.
  # https://discord.com/developers/docs/resources/sticker#delete-guild-sticker
  def delete_sticker(token, server_id, sticker_id, reason = nil)
    Discordrb::API.request(
      :guilds_sid_stickers_eid,
      server_id,
      :delete,
      "#{Discordrb::API.api_base}/guilds/#{server_id}/stickers/#{sticker_id}",
      Authorization: token,
      'X-Audit-Log-Reason': reason
    )
  end
end
