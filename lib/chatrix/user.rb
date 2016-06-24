require 'wisper'

module Chatrix
  class User < EventProcessor
    include Wisper::Publisher

    attr_reader :id, :displayname, :avatar

    def initialize(id, matrix)
      super()

      @id = id
      @matrix = matrix

      # room_id => membership
      @memberships = {}
    end

    def to_s
      return @displayname if @displayname
      @id
    end

    def process_member_event(room, event)
      return if processed? event

      content = event['content']

      @memberships[room.id] = content['membership']
      broadcast(:membership, self, room, content['membership'])

      update_avatar(content['avatar_url']) if content.key? 'avatar_url'
      update_displayname(content['displayname']) if content.key? 'displayname'

      processed event
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
