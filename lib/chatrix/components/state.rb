require 'chatrix/events'

require 'chatrix/components/permissions'

require 'set'
require 'wisper'

module Chatrix
  module Components
    # Manages state for a room.
    class State
      include Wisper::Publisher

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

        name = 'handle_' + event['type'].match(/\w+$/).to_s
        send(name, event) if respond_to? name, true

        Events.processed event
      end

      # Handle the `m.room.create` event.
      # @param event [Hash] Event data.
      def handle_create(event)
        @creator = @users.send(:get_user, event['content']['creator'])
        broadcast :creator, @room, @creator
      end

      # Handle the `m.room.canonical_alias` event.
      # @param (see #handle_create)
      def handle_canonical_alias(event)
        @canonical_alias = event['content']['alias']
        broadcast :canonical_alias, @room, @canonical_alias
      end

      # Handle the `m.room.aliases` event.
      # @param (see #handle_create)
      def handle_aliases(event)
        @aliases.replace event['content']['aliases']
        broadcast :aliases, @room, @aliases
      end

      # Handle the `m.room.name` event.
      # @param (see #handle_create)
      def handle_name(event)
        broadcast :name, @room, @name = event['content']['name']
      end

      # Handle the `m.room.topic` event.
      # @param (see #handle_create)
      def handle_topic(event)
        broadcast :topic, @room, @topic = event['content']['topic']
      end

      # Handle the `m.room.guest_access` event.
      # @param (see #handle_create)
      def handle_guest_access(event)
        @guest_access = event['content']['guest_access'] == 'can_join'
        broadcast :guest_access, @room, @guest_access
      end

      # Handle the `m.room.history_visibility` event.
      # @param (see #handle_create)
      def handle_history_visibility(event)
        @history_visibility = event['content']['history_visibility']
        broadcast :history_visibility, @room, @history_visibility
      end

      # Handle the `m.room.join_rules` event.
      # @param (see #handle_create)
      def handle_join_rules(event)
        @join_rule = event['content']['join_rule']
        broadcast :join_rule, @room, @join_rule
      end

      # Process a member event.
      # @param event [Hash] The member event.
      def handle_member(event)
        @users.process_member_event self, event
        user = @users[event['sender']]
        membership = event['content']['membership'].to_sym

        # Don't process invite state change if the user is already a
        # member in the room.
        return if membership == :invite && member?(user)

        if membership == :join
          @members.add user
        else
          @members.delete user
        end

        broadcast(membership, @room, user)
      end

      # Process a power level event.
      # @param event [Hash] Event data.
      def handle_power_levels(event)
        content = event['content']
        @permissions.update content
        @users.process_power_levels @room, content['users']
      end
    end
  end
end
