# encoding: utf-8
# frozen_string_literal: true

require 'chatrix/components/state'
require 'chatrix/components/timeline'
require 'chatrix/components/messaging'
require 'chatrix/components/permissions'
require 'chatrix/components/admin'

module Chatrix
  # Provides functionality for interacting with a room.
  class Room
    include Wisper::Publisher

    # @return [String] The ID of this room.
    attr_reader :id

    # @return [State] The state object for this room.
    attr_reader :state

    # @return [Timeline] The timeline object for this room.
    attr_reader :timeline

    # @return [Admin] Administration object for carrying out administrative
    #   actions like kicking and banning of users.
    attr_reader :admin

    # @return [Messaging] Handle various message actions through this object.
    attr_reader :messaging

    # Initializes a new Room instance.
    #
    # @param id [String] The room ID.
    # @param users [Users] The User manager.
    # @param matrix [Matrix] The Matrix API instance.
    def initialize(id, users, matrix)
      @id = id
      @users = users
      @matrix = matrix

      @state = Components::State.new self, @users
      @timeline = Components::Timeline.new self, @users
      @messaging = Components::Messaging.new self, @matrix
      @admin = Components::Admin.new self, @matrix
    end

    # Convenience method to get the canonical alias from this room's state.
    # @return [String] The canonical alias for this room.
    def canonical_alias
      @state.canonical_alias
    end

    # Convenience method to get the name from this room's state.
    # @return [String] The name for this room.
    def name
      @state.name
    end

    # Process join events for this room.
    # @param data [Hash] Event data containing state and timeline events.
    def process_join(data)
      @state.update data['state'] if data.key? 'state'
      @timeline.update data['timeline'] if data.key? 'timeline'
    end

    # Process invite events for this room.
    # @param data [Hash] Event data containing special invite data.
    def process_invite(data)
      data['invite_state']['events'].each { |e| process_invite_event e }
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
      name || canonical_alias || @id
    end

    private

    # Process an invite event for this room.
    # @param event [Hash] Event data.
    def process_invite_event(event)
      return unless event['type'] == 'm.room.member'
      return unless event['content']['membership'] == 'invite'
      @users.process_invite self, event
      sender = @users[event['sender']]
      invitee = @users[event['state_key']]
      # Return early if the user is already in the room
      return if @state.member? invitee
      broadcast(:invited, sender, invitee)
    end
  end
end
