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
        @matrix.rooms.actions.kick @room.id, user, reason
      end

      # Bans a user from the room.
      #
      # @param user [User,String] The user to kick, can be either a User
      #   object or a String (user ID).
      # @param reason [String] The reason for the ban.
      # @return [Boolean] `true` if the user was kicked, otherwise `false`.
      def ban(user, reason)
        @matrix.rooms.actions.ban @room.id, user, reason
      end

      # Unbans a user from the room.
      #
      # @param user [User,String] The user to unban, can be either a User
      #   objec or a String (user ID).
      # @return [Boolean] `true` if the user was unbanned, otherwise `false`.
      def unban(user)
        @matrix.rooms.actions.unban @room.id, user
      end
    end
  end
end
