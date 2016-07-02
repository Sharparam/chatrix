# encoding: utf-8
# frozen_string_literal: true

require 'chatrix/events'

require 'wisper'

module Chatrix
  # Describes a user.
  class User
    include Wisper::Publisher

    # @return [String] The user ID of this user.
    attr_reader :id

    # @return [String,nil] The display name of this user, if one has
    #   been set.
    attr_reader :displayname

    # @return [String,nil] This user's avatar URL, if one has been set.
    attr_reader :avatar

    # Initializes a new User instance.
    # @param id [String] The user ID.
    def initialize(id)
      @id = id

      # room_id => membership
      @memberships = {}
    end

    # Get this user's power level in a room.
    #
    # @param room [Room] The room to check.
    # @return [Fixnum] The user's power level in the specified room.
    def power_in(room)
      return 0 unless @memberships.key? room
      @memberships[room][:power] || 0
    end

    # Process a member event.
    #
    # @param room [Room] The room that sent the event.
    # @param event [Hash] Event data.
    def process_member_event(room, event)
      membership = (@memberships[room] ||= {})
      type = event['content']['membership'].to_sym

      # Only update the membership status if we are currently not in the room
      # or if the new state is that we have left.
      if membership[:type] != :join || type == :leave
        membership[:type] = type
        broadcast(:membership, self, room, membership)
      end

      update(event['content'])

      Events.processed event
    end

    # Process a power level update in a room.
    #
    # @param room [Room] The room where the level updated.
    # @param level [Fixnum] The new power level.
    def process_power_level(room, level)
      membership = (@memberships[room] ||= {})
      membership[:power] = level
      broadcast(:power_level, self, room, level)
    end

    # Process an invite to a room.
    # @param room [Room] The room the user was invited to.
    # @param sender [User] The user who sent the invite.
    # @param event [Hash] Event data.
    def process_invite(room, sender, event)
      # Return early if we're already part of this room
      membership = (@memberships[room] ||= {})
      return if membership[:type] == :join
      process_member_event room, event
      broadcast(:invited, self, room, sender)
    end

    # Converts this User object to a string representation of it.
    # @return [String] Returns the user's display name if one is set,
    #   otherwise returns the ID.
    def to_s
      @id
    end

    private

    # Updates metadata for this user.
    # @param data [Hash{String=>String}] User metadata.
    def update(data)
      update_avatar(data['avatar_url']) if data.key? 'avatar_url'
      update_displayname(data['displayname']) if data.key? 'displayname'
    end

    # Sets a new avatar URL for this user.
    # @param url [String] The new URL to set.
    def update_avatar(url)
      @avatar = url
      broadcast(:avatar, self, @avatar)
    end

    # Sets a new display name for this user.
    # @param name [String] The new name to set.
    def update_displayname(name)
      @displayname = name
      broadcast(:displayname, self, @displayname)
    end
  end
end
