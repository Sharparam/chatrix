require 'chatrix/user'

require 'wisper'

module Chatrix
  class Users
    include Wisper::Publisher

    def initialize(matrix)
      @matrix = matrix

      # user_id => user
      @users = {}
    end

    def [](id)
      return @users[id] if id.start_with? '@'

      res = @users.find { |i, u| u.displayname == id }
      res.last if res.respond_to? :last
    end

    def process_member_event(room, event)
      get_user(event['sender']).process_member_event room, event
    end

    def process_power_levels(room, data)
      data.each do |id, level|
        get_user(id).process_power_level room, level
      end
    end

    private

    def get_user(id)
      return @users[id] if @users.key? id
      user = User.new id, @matrix
      @users[id] = user
      broadcast(:added, user)
      user
    end
  end
end
