# frozen_string_literal: true

module Discordrb
  module API
    # API calls for Sticker object
    module Sticker
      module_function

      # Resolve a sticker
      # https://discord.com/developers/docs/resources/sticker#get-sticker
      def resolve(token, sticker_id)
        Discordrb::API.request(
          :stickers_sid,
          sticker_id,
          :get,
          "#{Discordrb::API.api_base}/stickers/#{sticker_id}",
          Authorization: token
        )
      end

      # List Nitro Stickers
      # https://discord.com/developers/docs/resources/sticker#list-nitro-sticker-packs
      def packs(token)
        Discordrb::API.request(
          :sticker_packs,
          nil,
          :get,
          "#{Discordrb::API.api_base}/sticker-packs",
          Authorization: token
        )
      end

      # List Server Stickers
      # https://discord.com/developers/docs/resources/sticker#list-guild-stickers
      def server_stickers(token, server_id)
        Discordrb::API.request(
          :guilds_sid_stickers,
          server_id,
          :get,
          "#{Discordrb::API.api_base}/guilds/#{server_id}/stickers",
          Authorization: token
        )
      end

      # List Server Stickers
      # https://discord.com/developers/docs/resources/sticker#get-guild-sticker
      def resolve_server_stickers(token, server_id, sticker_id)
        Discordrb::API.request(
          :guilds_sid_stickers_sid,
          server_id,
          :get,
          "#{Discordrb::API.api_base}/guilds/#{server_id}/stickers/#{sticker_id}",
          Authorization: token
        )
      end

      # Create Server Sticker
      # @param attributes [Hash] Attributes contains the following keys:
      # @option name [String] name of sticker
      # @option description [String] description of sticker
      # @option tags [Array<String>, String] array tags for the sticker, or comma separated string
      # @option file [File] the sticker file. PNG, APNG or LOTTIE. max 500kb
      # https://discord.com/developers/docs/resources/sticker#create-guild-sticker
      def create(token, server_id, **attributes)
        reason = attributes.delete(:reason)
        attributes[:tags] = attributes[:tags].join(',') if attributes[:tags].respond_to?(:join)
        body = attributes.slice(:name, :description, :tags, :file)

        raise(ArgumentError, 'Invalid file argument') unless body[:file].is_a?(File)

        Discordrb::API.request(
          :guilds_sid_stickers,
          server_id,
          :post,
          "#{Discordrb::API.api_base}/guilds/#{server_id}/stickers",
          body,
          Authorization: token,
          'X-Audit-Log-Reason': reason
        )
      end

      # Modify Server Sticker
      # @param server_id [String] Server ID.
      # @param sticker_id [String] Sticker ID.
      # @param attributes [Hash] Attributes contains the following keys:
      # @option name [String] name of sticker
      # @option description [String] description of sticker
      # @option tags [Array<String>, String] array tags for the sticker, or comma separated string
      # https://discord.com/developers/docs/resources/sticker#modify-guild-sticker
      def modify(token, server_id, sticker_id, **attributes)
        reason = attributes.delete(:reason)
        attributes[:tags] = attributes[:tags].join(',') if attributes[:tags].respond_to?(:join)
        body = attributes.slice(:name, :description, :tags)

        Discordrb::API.request(
          :guilds_sid_stickers_sid,
          server_id,
          :patch,
          "#{Discordrb::API.api_base}/guilds/#{server_id}/stickers/#{sticker_id}",
          body,
          Authorization: token,
          'X-Audit-Log-Reason': reason
        )
      end

      # Delete Server Sticker
      # https://discord.com/developers/docs/resources/sticker#delete-guild-sticker
      def delete(token, server_id, sticker_id, reason = nil)
        Discordrb::API.request(
          :guilds_sid_stickers_sid,
          server_id,
          :delete,
          "#{Discordrb::API.api_base}/guilds/#{server_id}/stickers/#{sticker_id}",
          Authorization: token,
          'X-Audit-Log-Reason': reason
        )
      end
    end
  end
end
