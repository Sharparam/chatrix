# encoding: utf-8
# frozen_string_literal: true

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

      # Joins the room. Can only be used on public rooms or if the user
      # has been invited.
      def join
        @matrix.rooms.actions.join @room.id
      end

      # Leaves the room. If the user is currently invited to the room,
      # leaving the room is the same as rejecting the invite.
      def leave
        @matrix.rooms.actions.leave @room.id
      end

      # Kicks a user from the room.
      #
      # @param user [User] The user to kick.
      # @param reason [String] The reason for the kick.
      # @return [Boolean] `true` if the user was kicked, otherwise `false`.
      def kick(user, reason)
        @matrix.rooms.actions.kick @room.id, user.id, reason
      end

      # Bans a user from the room.
      #
      # @param user [User] The user to kick.
      # @param reason [String] The reason for the ban.
      # @return [Boolean] `true` if the user was kicked, otherwise `false`.
      def ban(user, reason)
        @matrix.rooms.actions.ban @room.id, user.id, reason
      end

      # Unbans a user from the room.
      #
      # @param user [User] The user to unban.
      # @return [Boolean] `true` if the user was unbanned, otherwise `false`.
      def unban(user)
        @matrix.rooms.actions.unban @room.id, user.id
      end
    end
  end
end
