require 'chatrix/event_processor'
require 'chatrix/permissions'
require 'chatrix/message'

require 'logger'
require 'set'
require 'wisper'

module Chatrix
  # Provides functionality for interacting with a room.
  class Room < EventProcessor
    include Wisper::Publisher

    # Handlers for state events.
    STATE_HANDLERS = {
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
      'm.room.power_levels' => -> (event) { process_power_levels event },
      'm.room.member' => -> (event) { process_member_event event }
    }.freeze

    # @!attribute [r] id
    #   @return [String] The ID of this room.
    # @!attribute [r] alias
    #   @return [String,nil] This room's canonical alias, or `nil` if none
    #     has been set.
    # @!attribute [r] name
    #   @return [String,nil] The name of this room, or `nil` if none has
    #     been set.
    # @!attribute [r] topic
    #   @return [String,nil] The topic of this room, or `nil` if none has
    #     been set.
    # @!attribute [r] creator
    #   @return [User] The user who created this room.
    # @!attribute [r] guest_access
    #   @return [Boolean] `true` if guests are allowed in this room,
    #     otherwise `false`.
    # @!attribute [r] history_visibility
    #   @return [String] This room's history visibility.
    # @!attribute [r] join_rule
    #   @return [String] Join rules for this room.
    attr_reader :id, :alias, :name, :topic, :creator, :guest_access,
                :history_visibility, :join_rule

    # Initializes a new Room instance.
    #
    # @param id [String] The room ID.
    # @param users [Users] The User manager.
    # @param matrix [Matrix] The Matrix API instance.
    def initialize(id, users, matrix)
      super()

      @id = id
      @aliases = []
      @users = users
      @matrix = matrix
      @members = Set.new

      @permissions = Permissions.new self
    end

    # Sends a message to this channel.
    #
    # @param message [String] The message to send.
    # @return [String] Event ID for the send action.
    def send_message(message)
      @matrix.send_message @id, message
    end

    # Sends a notice to this channel.
    #
    # @param message [String] The notice to send.
    # @return (see #send_message)
    def send_notice(message)
      @matrix.send_notice @id, message
    end

    # Sends an emote to this channel.
    #
    # @param message [String] The emote text to send.
    # @return (see #send_message)
    def send_emote(message)
      @matrix.send_emote @id, message
    end

    # Check if a user can perform an action in this room.
    #
    # @param user [User] The user to test.
    # @param action [Symbol] The action to check.
    # @return [Boolean] `true` if the user can perform the action,
    #   otherwise `false`.
    def can?(user, action)
      @permissions.can? user, action
    end

    # Check if a user can set an event in this room.
    #
    # @param user [User] The user to test.
    # @param event [Symbol] The event to check.
    # @return [Boolean] `true` if the user can set the event,
    #   otherwise `false`.
    def can_set?(user, event)
      @permissions.can_set? user, event
    end

    # Process join events for this room.
    # @param data [Hash] Event data containing state and timeline events.
    def process_join(data)
      process_state data['state'] if data.key? 'state'
      process_timeline data['timeline'] if data.key? 'timeline'
    end

    def process_invite(data)
    end

    # Process leave events for this room.
    # @param data [Hash] Event data containing state and timeline events up
    #   until the point of leaving the room.
    def process_leave(data)
      process_state data['state'] if data.key? 'state'
      process_timeline data['timeline'] if data.key? 'timeline'
    end

    # Gets a string representation of this room.
    # @return [String] If the room has a name, that name is returned.
    #   If it has a canonical alias, the alias is returned.
    #   If it has neither a name nor alias, the room ID is returned.
    def to_s
      @name || @alias || @id
    end

    private

    # Process state events.
    # @param data [Hash] Events to process.
    def process_state(data)
      return unless data.key? 'events'
      data['events'].each { |e| process_state_event e }
    end

    # Process timeline events.
    # @param data [Hash] Events to process.
    def process_timeline(data)
      return unless data.key? 'events'
      data['events'].each { |e| process_timeline_event e }
    end

    # Process a state event.
    # @param event [Hash] The event to process.
    def process_state_event(event)
      return if processed? event

      broadcast(:state, self, event)

      case h = STATE_HANDLERS[event['type']]
      when Proc
        h.call event
      when Array
        broadcast h.first, self, h.last.call(event['content'][h.first])
      end

      processed event
    end

    # Process a member event.
    # @param event [Hash] The member event.
    def process_member_event(event)
      @users.process_member_event self, event
      user = @users[event['sender']]
      membership = event['membership'].to_sym

      if membership == :join
        @members.add user
      else
        @members.delete user
      end

      broadcast(membership, self, user)
    end

    # Process a power level event.
    # @param event [Hash] Event data.
    def process_power_levels_event(event)
      content = event['content']
      @permissions.update content
      broadcast(:permissions, self)
      @users.process_power_levels self, content['users']
    end

    # Process a timeline event.
    # @param event [Hash] Event data.
    def process_timeline_event(event)
      return if processed? event

      broadcast(:timeline, self, event)

      case event['type']
      when 'm.room.message'
        process_message_event event
      when 'm.room.member'
        process_member_event event
      end

      processed event
    end

    # Process a message event.
    # @param event [Hash] Event data.
    def process_message_event(event)
      message = Message.new @users[event['sender']], event['content']
      broadcast(:message, self, message)
    end
  end
end
