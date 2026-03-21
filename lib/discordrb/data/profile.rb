# frozen_string_literal: true

module Discordrb
  # This class is a special variant of User that represents the bot's user profile (things like own username and the avatar).
  # It can be accessed using {Bot#profile}.
  class Profile < User
    # Whether or not the user is the bot. The Profile can only ever be the bot user, so this always returns true.
    # @return [true]
    def current_bot?
      true
    end

    # Sets the bot's username.
    # @param username [String] The new username.
    def username=(username)
      modify(username: username)
    end

    alias_method :name=, :username=

    # Changes the bot's avatar.
    # @param avatar [String, File, #read, nil] A file to be used as the avatar, either
    #  something readable (e.g. File Object) or a data URI.
    def avatar=(avatar)
      modify(avatar: avatar)
    end

    # Changes the bot's banner.
    # @param banner [String, File, #read, nil] A file to be used as the banner, either
    #  something readable (e.g. File Object) or a data URI.
    def banner=(banner)
      modify(banner: banner)
    end

    # Modify the properties of the current bot.
    # @param username [String] The new username to set for the bot.
    # @param avatar [String, File, #read, nil] The new avatar to set for the bot. Should
    #  be something readable (e.g. File Object) or a data URI.
    # @param banner [String, File, #read, nil] The new banner to set for the bot. Should
    #  be something readable (e.g. File Object) or a data URI.
    # @return [nil]
    def modify(username: :undef, avatar: :undef, banner: :undef)
      avatar = avatar.respond_to?(:read) ? Discordrb.encode64(avatar) : avatar
      banner = banner.respond_to?(:read) ? Discordrb.encode64(banner) : banner
      update_data(JSON.parse(API::User.update_current_user(@bot.token, username, avatar, banner)))
      nil
    end

    # Get the bot's global bio.
    # @return [String] The bot's global bio, or an empty string if it doesn't have one set.
    def bio
      @bot.application.description
    end

    # Set the bot's global bio.
    # @param bio [String, nil] The bot's new global bio, or `nil` to remove the current bio.
    def bio=(bio)
      @bot.application.modify(description: bio)
    end

    # Updates the cached profile data with the new one.
    # @note For internal use only.
    # @!visibility private
    def update_data(new_data)
      @username = new_data['username']
      @avatar_id = new_data['avatar']
      @banner_id = new_data['banner']
    end

    # The inspect method is overwritten to give more useful output
    def inspect
      "<Profile user=#{super}>"
    end
  end
end
