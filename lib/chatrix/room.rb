require 'chatrix/event_processor'

require 'logger'
require 'wisper'

module Chatrix
  class Room < EventProcessor
    include Wisper::Publisher

    attr_reader :id

    # Debugging
    @@log = Logger.new $stdout

    def initialize(id, matrix)
      super

      @id = id
      @matrix = matrix
      @members = {}
    end

    def send_message(message)
      @matrix.send_message @id, message
    end

    def process_join(data)
      process_state data['state'] if data.key? 'state'
      process_timeline data['timeline'] if data.key? 'timeline'
    end

    def process_state(data)
      return unless data.key? 'events'
      data['events'].each { |e| process_state_event e }
    end

    def process_timeline(data)
      return unless data.key? 'events'
      data['events'].each { |e| process_timeline_event e }
    end

    def process_state_event(event)
      return if processed? event

      @@log.debug { "Processing state event: #{event}" }

      return unless event['type'] == 'm.room.member'

      @members[event['sender']] = event['content']['membership']
      broadcast(:user_update, event['sender'])
      processed event
    end

    def process_timeline_event(event)
      return if processed? event

      @@log.debug { "Processing timeline event: #{event}" }

      case event['type']
      when 'm.room.message'
        message = event['content']['body']
        sender = event['sender']
        broadcast(:message, sender, message)
      when 'm.room.member'
        @members[event['sender']] = event['content']['membership']
        broadcast(:user_update, event['sender'])
      end

      processed event
    end
  end
end
