require 'chatrix/event_processor'

require 'wisper'

module Chatrix
  # Describes a user
  class User < EventProcessor
    include Wisper::Publisher

    attr_reader :id, :displayname, :avatar

    def initialize(id)
      super()

      @id = id

      # room_id => membership
      @memberships = {}
    end

    def power_in(room)
      return 0 unless @memberships.key? room
      @memberships[room][:power] || 0
    end

    def can?(action, room)
      room.can? self, action
    end

    def can_set?(event, room)
      room.can_set? self, event
    end

    def process_member_event(room, event)
      return if processed? event

      content = event['content']

      membership = (@memberships[room] ||= {})
      membership[:type] = content['membership']

      broadcast(:membership, self, room, membership)

      update_avatar(content['avatar_url']) if content.key? 'avatar_url'
      update_displayname(content['displayname']) if content.key? 'displayname'

      processed event
    end

    def process_power_level(room, level)
      membership = (@memberships[room] ||= {})
      membership[:power] = level
      broadcast(:membership, self, room, membership)
    end

    def to_s
      return @displayname if @displayname
      @id
    end

    private

    def update_avatar(url)
      @avatar = url
      broadcast(:avatar, self, @avatar)
    end

    def update_displayname(name)
      @displayname = name
      broadcast(:displayname, self, @displayname)
    end
  end
end
