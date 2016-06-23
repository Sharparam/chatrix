require 'chatrix/room'

require 'wisper'

module Chatrix
  class Rooms
    include Wisper::Publisher

    def initialize(matrix)
      @matrix = matrix

      # room_id => room
      @rooms = {}
    end

    # Gets a room by its ID.
    #
    # If the room has not been discovered, returns `nil`.
    def [](id)
      @rooms[id]
    end

    # Processes a list of room events from syncs
    def process_events(events)
      process_join events['join'] if events.key? 'join'
      process_invite events['invite'] if events.key? 'invite'
      process_leave events['leave'] if events.key? 'leave'
    end

    private

    def get_room(id)
      return @rooms[id] if @rooms.key? id
      room = Room.new id, @matrix
      broadcast(:added, room)
      room
    end

    def process_join(events)
      events.each do |room, data|
        get_room(room).process_join data
      end
    end

    def process_invite(events)
      events.each do |room, data|
        get_room(room).process_invite data
      end
    end

    def process_leave(events)
      events.each do |room, data|
        get_room(room).process_leave data
      end
    end
  end
end
