require 'chatrix/events'

require 'chatrix/components/permissions'

require 'set'
require 'wisper'

module Chatrix
  module Components
    # Manages state for a room.
    class State
      include Wisper::Publisher

      # State event handlers.
      HANDLERS = {
        'm.room.create' =>
          ['creator', -> (val) { @creator = @users.send(:get_user, val) }],
        'm.room.canonical_alias' => ['alias', -> (val) { @alias = val }],
        'm.room.aliases' => ['aliases', -> (val) { @aliases.replace val }],
        'm.room.name' => ['name', -> (val) { @name = val }],
        'm.room.topic' => ['topic', -> (val) { @topic = val }],
        'm.room.guest_access' =>
          ['guest_access', -> (val) { @guest_access = val == 'can_join' }],
        'm.room.history_visibility' =>
          ['history_visibility', -> (val) { @history_visibility = val }],
        'm.room.join_rules' => ['join_rule', -> (val) { @join_rule = val }],
        'm.room.member' => -> (e) { process_member e },
        'm.room.power_levels' => -> (e) { process_power_levels e }
      }.freeze

      # @!attribute [r] canonical_alias
      #   @return [String,nil] The canonical alias, or `nil` if none has
      #     been set.
      # @!attribute [r] name
      #   @return [String,nil] The name, or `nil` if none has been set.
      # @!attribute [r] topic
      #   @return [String,nil] The topic, or `nil` if none has been set.
      # @!attribute [r] creator
      #   @return [User] The user who created the room.
      # @!attribute [r] guest_access
      #   @return [Boolean] `true` if guests are allowed in the room,
      #     otherwise `false`.
      # @!attribute [r] history_visibility
      #   @return [String] The room's history visibility.
      # @!attribute [r] join_rule
      #   @return [String] Join rules for the room.
      # @!attribute [r] permissions
      #   @return [Permissions] Check room permissions.
      attr_reader :canonical_alias, :name, :topic, :creator, :guest_access,
                  :join_rule, :history_visibility, :permissions

      # Initializes a new State instance.
      #
      # @param room [Room] The room the state belongs to.
      # @param users [Users] The user manager.
      def initialize(room, users)
        @room = room
        @users = users

        @permissions = Permissions.new @room

        @aliases = []
        @members = Set.new
      end

      # Returns whether the specified user is a member of the room.
      #
      # @param user [User] The user to check.
      # @return [Boolean] `true` if the user is a member of the room,
      #   otherwise `false`.
      def member?(user)
        @members.member? user
      end

      # Updates the state with new event data.
      # @param data [Hash] Event data.
      def update(data)
        data['events'].each { |e| process_event e } if data.key? 'events'
      end

      private

      # Processes a state event.
      # @param event [Hash] Event data.
      def process_event(event)
        return if Events.processed? event

        case h = HANDLERS[event['type']]
        when Array
          broadcast h.first, @room, h.last.call(event['content'][h.first])
        when Proc
          h.call(event)
        end

        Events.processed event
      end

      # Process a member event.
      # @param event [Hash] The member event.
      def process_member(event)
        @users.process_member_event self, event
        user = @users[event['sender']]
        membership = event['membership'].to_sym

        if membership == :join
          @members.add user
        else
          @members.delete user
        end

        broadcast(membership, @room, user)
      end

      # Process a power level event.
      # @param event [Hash] Event data.
      def process_power_levels(event)
        content = event['content']
        @permissions.update content
        @users.process_power_levels @room, content['users']
      end
    end
  end
end
