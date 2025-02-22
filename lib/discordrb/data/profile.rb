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
      update_profile_data(username: username)
    end

    alias_method :name=, :username=

    # Changes the bot's avatar.
    # @param avatar [String, #read] A JPG file to be used as the avatar, either
    #  something readable (e.g. File Object) or as a data URL.
    def avatar=(avatar)
      if avatar.respond_to? :read
        update_profile_data(avatar: encode_file(avatar))
      else
        update_profile_data(avatar: avatar)
      end
    end

    # Changes the bot's banner.
    # @param banner [String, #read] The base64 encoded string with the image data
    #  or something that responds to #read.
    def banner=(banner)
      if banner.respond_to? :read
        update_profile_data(banner: encode_file(banner))
      else
        update_profile_data(banner: banner)
      end
    end

    # Updates the cached profile data with the new one.
    # @note For internal use only.
    # @!visibility private
    def update_data(new_data)
      @username = new_data[:username] || @username
      @avatar_id = new_data[:avatar_id] || @avatar_id
      @banner_id = new_data[:banner_id] || @banner_id
    end

    # The inspect method is overwritten to give more useful output
    def inspect
      "<Profile user=#{super}>"
    end

    private

    def update_profile_data(new_data)
      API::User.update_profile(@bot.token,
                               new_data.key?(:username) ? new_data[:username] : :undef,
                               new_data.key?(:avatar) ? new_data[:avatar] : :undef,
                               new_data.key?(:banner) ? new_data[:banner] : :undef)
      update_data(new_data)
    end
  end
end
