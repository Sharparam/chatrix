module Chatrix
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
      case event
      when String
        event
      when Hash
        if event.key? 'event_id'
          event['event_id']
        else
          raise ArgumentError, 'event hash is missing event_id value'
        end
      else
        raise ArgumentError, 'Invalid event object'
      end
    end
  end
end
