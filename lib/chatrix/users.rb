require 'chatrix/user'
require 'chatrix/events'

require 'wisper'

module Chatrix
  # Manages the users known to the client.
  class Users
    include Wisper::Publisher

    # Initializes a new Users instance.
    def initialize
      # user_id => user
      @users = {}
    end

    # Gets a user by ID or display name.
    #
    # @param id [String] A user's ID or display name.
    # @return [User,nil] The User instance for the specified user, or
    #   `nil` if the user could not be found.
    def [](id)
      return @users[id] if id.start_with? '@'

      res = @users.find { |_, u| u.displayname == id }
      res.last if res.respond_to? :last
    end

    # Process a member event.
    #
    # @param room [Room] Which room the events are related to.
    # @param event [Hash] Event data.
    def process_member_event(room, event)
      return if Events.processed? event
      get_user(event['sender']).process_member_event room, event
    end

    # Process power level updates.
    #
    # @param room [Room] The room this event came from.
    # @param data [Hash{String=>Fixnum}] Power level data, a hash of user IDs
    #   and their associated power level.
    def process_power_levels(room, data)
      data.each do |id, level|
        get_user(id).process_power_level room, level
      end
    end

    # Process an invite event for a room.
    #
    # @param room [Room] The room from which the event originated.
    # @param event [Hash] Event data.
    def process_invite(room, event)
      sender = get_user(event['sender'])
      invitee = get_user(event['state_key'])
      invitee.process_invite room, sender, event
    end

    private

    # Get the user instance for a specified user ID.
    # If an instance does not exist for the user, one is created and returned.
    #
    # @param id [String] The user ID to get an instance for.
    # @return [User] An instance of User for the specified ID.
    def get_user(id)
      return @users[id] if @users.key? id
      user = User.new id
      @users[id] = user
      broadcast(:added, user)
      user
    end
  end
end
