module Chatrix
  class Permissions
    def initialize(room)
      @room = room
      @actions = {}
      @events = {}
    end

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

    def can?(user, action)
      return false unless @actions.key? action
      user.power_in(@room) >= @actions[action]
    end

    def can_set?(user, event)
      return false unless @events.key? event
      user.power_in(@room) >= @events[event]
    end
  end
end
