require 'chatrix/room'

require 'wisper'

module Chatrix
  class Rooms
    include Wisper::Publisher

    def initialize(users, matrix)
      @matrix = matrix

      @users = users

      # room_id => room
      @rooms = {}
    end

    # Gets a room by its ID, alias, or name.
    #
    # If the room has not been discovered, returns `nil`.
    def [](id)
      return @rooms[id] if id.start_with? '!'

      if id.start_with? '#'
        res = @rooms.find { |_, r| r.alias == id }
        return res.last if res.respond_to? :last
      end

      res = @rooms.find { |_, r| r.name == id }
      res.last if res.respond_to? :last
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
      room = Room.new id, @users, @matrix
      @rooms[id] = room
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
