module Chatrix
  # Keeps track of what events have already been processed.
  class EventProcessor
    def initialize
      @processed = []
    end

    def processed(event)
      @processed.push parse_event event
    end

    def processed?(event)
      @processed.member? parse_event event
    end

    private

    def parse_event(event)
      if event.is_a? String
        event
      elsif event.is_a?(Hash) && event.key?('event_id')
        event['event_id']
      else
        raise ArgumentError, 'Invalid event object'
      end
    end
  end
end
