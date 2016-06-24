require 'chatrix/user'

module Chatrix
  module Components
    # Provides administrative actions for a room.
    class Admin
      # Initializes a new Admin instance.
      #
      # @param room [Room] The room to administrate.
      # @param matrix [Matrix] Matrix API instance.
      def initialize(room, matrix)
        @room = room
        @matrix = matrix
      end

      # Kicks a user from the room.
      #
      # @param user [User,String] The user to kick, can be either a User
      #   object or a String (user ID).
      # @param reason [String] The reason for the kick.
      # @return [Boolean] `true` if the user was kicked, otherwise `false`.
      def kick(user, reason)
        @matrix.kick @room.id, resolve_user(user), reason
      end

      # Bans a user from the room.
      #
      # @param user [User,String] The user to kick, can be either a User
      #   object or a String (user ID).
      # @param reason [String] The reason for the ban.
      # @return [Boolean] `true` if the user was kicked, otherwise `false`.
      def ban(user, reason)
        @matrix.ban @room.id, resolve_user(user), reason
      end

      private

      # Resolves a user object into a user ID.
      # @param user [User,String] The object to convert, can be a user ID or
      #   user object.
      # @return [String] A user ID for the user.
      def resolve_user(user)
        case user
        when String
          user
        when User
          user.id
        else
          raise ArgumentError, 'Invalid user object'
        end
      end
    end
  end
end
