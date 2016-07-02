# encoding: utf-8
# frozen_string_literal: true

require 'wisper'

module Chatrix
  module Components
    # Helper for parsing permissions in a room.
    class Permissions
      include Wisper::Publisher

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

        content['events'].each do |event, level|
          @events[event.match(/\w+$/).to_s.to_sym] = level
        end

        broadcast :update, @room, self
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
