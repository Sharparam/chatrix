require 'chatrix/components/state'
require 'chatrix/components/timeline'
require 'chatrix/components/messaging'
require 'chatrix/components/permissions'
require 'chatrix/components/admin'

module Chatrix
  # Provides functionality for interacting with a room.
  class Room
    include Wisper::Publisher

    # @!attribute [r] id
    #   @return [String] The ID of this room.
    # @!attribute [r] admin
    #   @return [Admin] Administration object for carrying out administrative
    #     actions like kicking and banning of users.
    # @!attribute [r] messaging
    #   @return [Messaging] Handle various message actions through this object.
    attr_reader :id, :state, :timeline, :admin, :messaging

    # Initializes a new Room instance.
    #
    # @param id [String] The room ID.
    # @param users [Users] The User manager.
    # @param matrix [Matrix] The Matrix API instance.
    def initialize(id, users, matrix)
      @id = id
      @users = users
      @matrix = matrix

      @state = State.new self, @users
      @timeline = Timeline.new self, @users
      @messaging = Messaging.new self, @matrix
      @admin = Admin.new self, @matrix
    end

    # Process join events for this room.
    # @param data [Hash] Event data containing state and timeline events.
    def process_join(data)
      @state.update data['state'] if data.key? 'state'
      @timeline.update data['timeline'] if data.key? 'timeline'
    end

    def process_invite(data)
    end

    # Process leave events for this room.
    # @param data [Hash] Event data containing state and timeline events up
    #   until the point of leaving the room.
    def process_leave(data)
      @state.update data['state'] if data.key? 'state'
      @timeline.update data['timeline'] if data.key? 'timeline'
    end

    # Gets a string representation of this room.
    # @return [String] If the room has a name, that name is returned.
    #   If it has a canonical alias, the alias is returned.
    #   If it has neither a name nor alias, the room ID is returned.
    def to_s
      @state.name || @state.alias || @id
    end
  end
end
