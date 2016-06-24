module Chatrix
  module Components
    # Helper for parsing permissions in a room.
    class Permissions
      # Initializes a new Permissions instance.
      # @param room [Room] The room that this permissions set belongs to.
      def initialize(room)
        @room = room
        @actions = {}
        @events = {}
      end

      # Updates permission data.
      # @param content [Hash] New permission data.
      def update(content)
        @actions[:ban] = content['ban']
        @actions[:kick] = content['kick']
        @actions[:invite] = content['invite']
        @actions[:redact] = content['redact']

        events = content['events']
        @events[:avatar] = events['m.room.avatar']
        @events[:alias] = events['m.room.canonical_alias']
        @events[:history_visibility] = events['m.room.history_visibility']
        @events[:name] = events['m.room.name']
        @events[:power_levels] = events['m.room.power_levels']
      end

      # Check if a user can perform an action.
      #
      # @param user [User] The user to test.
      # @param action [Symbol] The action to check.
      # @return [Boolean] `true` if the user can perform the action,
      #   otherwise `false`.
      def can?(user, action)
        return false unless @actions.key? action
        user.power_in(@room) >= @actions[action]
      end

      # Check if a user can set an event.
      #
      # @param user [User] The user to test.
      # @param event [Symbol] The event to check.
      # @return [Boolean] `true` if the user can set the event,
      #   otherwise `false`.
      def can_set?(user, event)
        return false unless @events.key? event
        user.power_in(@room) >= @events[event]
      end
    end
  end
end
