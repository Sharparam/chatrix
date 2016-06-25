require 'chatrix/message'
require 'chatrix/events'

require 'wisper'

module Chatrix
  module Components
    # Manages the timeline for a room.
    class Timeline
      include Wisper::Publisher

      # Handlers for timeline events.
      HANDLERS = {
        'm.room.message' => -> (event) { process_message event }
      }.freeze

      # Initializes a new Timeline instance.
      #
      # @param room [Room] The room this timeline belongs to.
      # @param users [Users] The user manager.
      def initialize(room, users)
        @room = room
        @users = users
      end

      # Process timeline events.
      # @param data [Hash] Events to process.
      def update(data)
        data['events'].each { |e| process_event e } if data.key? 'events'

        # Pass the event data to state to handle any state updates
        # in the timeline
        @room.state.update data
      end

      private

      # Processes a timeline event.
      # @param event [Hash] Event data.
      def process_event(event)
        return if Events.processed? event
        HANDLERS[event['type']].tap { |h| h.call(event) if h }
      end

      # Process a message event.
      # @param event [Hash] Event data.
      def process_message(event)
        message = Message.new @users[event['sender']], event['content']
        broadcast(:message, self, message)
        Events.processed event
      end
    end
  end
end
