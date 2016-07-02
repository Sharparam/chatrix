# encoding: utf-8
# frozen_string_literal: true

module Chatrix
  # Keeps track of what events have already been processed.
  module Events
    @processed = []

    # Marks an event as having been processed.
    # @param event [String,Hash] The affected event.
    def self.processed(event)
      @processed.push parse_event event
    end

    # Checks if an event has been processed.
    #
    # @param event [String,Hash] The event to check.
    # @return [Boolean] `true` if the event has been processed,
    #   otherwise `false`.
    def self.processed?(event)
      @processed.member? parse_event event
    end

    # Extract the event ID from an event object.
    # If this is a string, it's returned verbatim.
    #
    # @param event [String,Hash] The event object to extract information from.
    # @return [String] The event ID.
    #
    # @raise ArgumentError if the event object is of an invalid type or does
    #   not contain an ID.
    def self.parse_event(event)
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
