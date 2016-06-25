module Chatrix
  module Components
    # Class to handle messaging actions for a room.
    class Messaging
      # Initializes a new Messaging instance.
      # @param room [Room] The room to handle messaging for.
      # @param matrix [Matrix] Matrix API instance.
      def initialize(room, matrix)
        @room = room
        @matrix = matrix
      end

      # Sends a message to the room.
      # @param message [String] The message to send.
      # @return [String] Event ID for the send action.
      def send_message(message)
        @matrix.rooms.actions.send_message @room.id, message
      end

      # Sends a notice to the room.
      # @param message [String] The notice to send.
      # @return (see #send_message)
      def send_notice(message)
        @matrix.rooms.actions.send_message @room.id, message, 'm.notice'
      end

      # Sends an emote to the room.
      # @param message [String] The emote text to send.
      # @return (see #send_message)
      def send_emote(message)
        @matrix.rooms.actions.send_message @room.id, message, 'm.emote'
      end

      # Sends an HTML message to the room.
      # @param message [String] The HTML formatted message to send.
      # @return (see #send_message)
      def send_html(message)
        @matrix.rooms.actions.send_html @room.id, message
      end
    end
  end
end
