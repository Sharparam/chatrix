# encoding: utf-8
# frozen_string_literal: true

require 'chatrix/room'

require 'wisper'

module Chatrix
  # Manages the rooms known to the client.
  class Rooms
    include Wisper::Publisher

    # Initializes a new Rooms instance.
    #
    # @param users [Users] The User manager.
    # @param matrix [Matrix] The Matrix API instance.
    def initialize(users, matrix)
      @matrix = matrix

      @users = users

      # room_id => room
      @rooms = {}
    end

    # Gets a room by its ID, alias, or name.
    #
    # @return [Room,nil] Returns the room instance if the room was found,
    #   otherwise `nil`.
    def [](id)
      return @rooms[id] if id.start_with? '!'

      if id.start_with? '#'
        res = @rooms.find { |_, r| r.canonical_alias == id }
        return res.last if res.respond_to? :last
      end

      res = @rooms.find { |_, r| r.name == id }
      res.last if res.respond_to? :last
    end

    # Attempts to join the specified room.
    # @param id [String] The room ID to join.
    # @return [Room] The Room instance for the joined room.
    # @raise [ForbiddenError] Raised if the user does not have sufficient
    #   permissions to join the room.
    def join(id)
      get_room(id).tap(&:join)
    end

    # Processes a list of room events from syncs.
    #
    # @param events [Hash] A hash of room events as returned from the server.
    def process_events(events)
      process_join events['join'] if events.key? 'join'
      process_invite events['invite'] if events.key? 'invite'
      process_leave events['leave'] if events.key? 'leave'
    end

    private

    # Gets the Room instance associated with a room ID.
    # If there is no Room instance for the ID, one is created and returned.
    #
    # @param id [String] The room ID to get an instance for.
    # @return [Room] An instance of the Room class for the specified ID.
    def get_room(id)
      return @rooms[id] if @rooms.key? id
      room = Room.new id, @users, @matrix
      @rooms[id] = room
      broadcast(:added, room)
      room
    end

    # Process `join` room events.
    #
    # @param events [Hash{String=>Hash}] Events to process.
    def process_join(events)
      events.each do |room, data|
        get_room(room).process_join data
      end
    end

    # Process `invite` room events.
    #
    # @param events [Hash{String=>Hash}] Events to process.
    def process_invite(events)
      events.each do |room, data|
        get_room(room).process_invite data
      end
    end

    # Process `leave` room events.
    #
    # @param events [Hash{String=>Hash}] Events to process.
    def process_leave(events)
      events.each do |room, data|
        get_room(room).process_leave data
      end
    end
  end
end
