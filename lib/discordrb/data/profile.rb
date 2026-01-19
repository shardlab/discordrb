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
    # @param avatar [String, File, #read, nil] A file to be used as the avatar, either
    #  something readable (e.g. File Object) or a data URI.
    def avatar=(avatar)
      if avatar.respond_to?(:read)
        update_profile_data(avatar: Discordrb.encode64(avatar))
      else
        update_profile_data(avatar: avatar)
      end
    end

    # Changes the bot's banner.
    # @param banner [String, File, #read, nil] A file to be used as the banner, either
    #  something readable (e.g. File Object) or a data URI.
    def banner=(banner)
      if banner.respond_to?(:read)
        update_profile_data(banner: Discordrb.encode64(banner))
      else
        update_profile_data(banner: banner)
      end
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

    private

    # @!visibility private
    def update_profile_data(new_data)
      update_data(JSON.parse(API::User.update_current_user(@bot.token,
                                                           new_data[:username] || :undef,
                                                           new_data.key?(:avatar) ? new_data[:avatar] : :undef,
                                                           new_data.key?(:banner) ? new_data[:banner] : :undef)))
    end
  end
end
