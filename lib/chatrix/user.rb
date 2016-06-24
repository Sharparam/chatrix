require 'chatrix/event_processor'

require 'wisper'

module Chatrix
  # Describes a user.
  class User < EventProcessor
    include Wisper::Publisher

    # @!attribute [r] id
    #   @return [String] The user ID of this user.
    # @!attribute [r] displayname
    #   @return [String,nil] The display name of this user, if one has
    #     been set.
    # @!attribute [r] avatar
    #   @return [String,nil] This user's avatar URL, if one has been set.
    attr_reader :id, :displayname, :avatar

    # Initializes a new User instance.
    # @param id [String] The user ID.
    def initialize(id)
      super()

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

    # Check if this user can perform a certain action in the specified room.
    #
    # @param action [Symbol] The action to check permission for.
    # @param room [Room] The room to check permissions in.
    # @return [Boolean] `true` if the user can perform the action in the room,
    #   otherwise `false`.
    def can?(action, room)
      room.can? self, action
    end

    # Check if this user can set an event in the specified room.
    #
    # @param event [Symbol] The event to check permission for.
    # @param room [Room] The room to check permissions in.
    # @return [Boolean] `true` if the user can set the event in the room,
    #   otherwise `false`.
    def can_set?(event, room)
      room.can_set? self, event
    end

    # Process a member event.
    #
    # @param room [Room] The room that sent the event.
    # @param event [Hash] Event data.
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

    # Process a power level update in a room.
    #
    # @param room [Room] The room where the level updated.
    # @param level [Fixnum] The new power level.
    def process_power_level(room, level)
      membership = (@memberships[room] ||= {})
      membership[:power] = level
      broadcast(:membership, self, room, membership)
    end

    # Converts this User object to a string representation of it.
    # @return [String] Returns the user's display name if one is set,
    #   otherwise returns the ID.
    def to_s
      return @displayname if @displayname
      @id
    end

    private

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
