# encoding: utf-8
# frozen_string_literal: true

require 'chatrix/message'
require 'chatrix/events'

require 'wisper'

module Chatrix
  module Components
    # Manages the timeline for a room.
    class Timeline
      include Wisper::Publisher

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
        name = 'handle_' + event['type'].match(/\w+$/).to_s
        send(name, event) if respond_to? name, true
      end

      # Process a message event.
      # @param event [Hash] Event data.
      def handle_message(event)
        sender = @users[event['sender']]
        timestamp = event['origin_server_ts'] || Time.now.to_i
        content = event['content']
        message = Message.new sender, timestamp, content
        broadcast(:message, @room, message)
        Events.processed event
      end
    end
  end
end
