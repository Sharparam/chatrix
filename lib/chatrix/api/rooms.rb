require 'chatrix/api/api_component'
require 'chatrix/api/room_actions'

module Chatrix
  module Api
    # Contains methods for using room endpoints in the API.
    class Rooms < ApiComponent
      # @!attribute [r] actions
      #   @return [RoomActions] An instance of RoomActions to perform
      #     room actions such as joining a room or sending messages.
      attr_reader :actions

      # Initializes a new Rooms instance.
      # @param matrix [Matrix] The matrix API instance.
      def initialize(matrix)
        super
        @actions = Api::RoomActions.new @matrix
      end

      # Get the list of public rooms on the server.
      #
      # The `start` and `end` values returned in the result can be passed to
      # `from` and `to`, for pagination purposes.
      #
      # @param from [String] The stream token to start looking from.
      # @param to [String] The stream token to stop looking at.
      # @param limit [Fixnum] Maximum number of results to
      #   return in one request.
      # @param direction ['f', 'b'] Direction to look in.
      # @return [Hash] Hash containing the list of rooms (in the `chunk` value),
      #   and pagination parameters `start` and `end`.
      def get_rooms(from: 'START', to: 'END', limit: 10, direction: 'b')
        make_request(
          :get,
          '/publicRooms',
          params: { from: from, to: to, limit: limit, dir: direction }
        ).parsed_response
      end

      # Get tags that a specific user has set on a room.
      #
      # @param user [String] The user whose settings to retrieve
      #   (`@user:host.tld`).
      # @param room [String] The room to get tags from.
      # @return [Hash{String=>Hash}] A hash with tag data. The tag name is
      #   the key and any additional metadata is contained in the Hash value.
      def get_user_tags(user, room)
        make_request(:get, "/user/#{user}/rooms/#{room}/tags")['tags']
      end

      # Get information about a room alias.
      #
      # This can be used to get the room ID that an alias points to.
      #
      # @param room_alias [String] The room alias to query, this **must** be an
      #   alias and not an ID.
      # @return [Hash] Returns information about the alias in a Hash.
      #
      # @see #get_room_id #get_room_id is an example of how this method could be
      #   used to get a room's ID.
      def get_alias_info(room_alias)
        make_request(:get, "/directory/room/#{room_alias}").parsed_response
      rescue NotFoundError
        raise RoomNotFoundError.new(room_alias),
              'The specified room alias could not be found'
      end

      # Get a room's ID from its alias.
      #
      # @param room_alias [String] The room alias to query.
      # @return [String] The actual room ID for the room.
      def get_id(room_alias)
        get_room_alias_info(room_alias)['room_id']
      end

      # Gets context for an event in a room.
      #
      # The method will return events that happened before and after the
      # specified event.
      #
      # @param room [String] The room to query.
      # @param event [String] The event to get context for.
      # @param limit [Fixnum] Maximum number of events to retrieve.
      # @return [Hash] The returned hash contains information about the events
      #   happening before and after the specified event, as well as start and
      #   end timestamps and state information for the event.
      def get_event_context(room, event, limit = 10)
        make_request(
          :get,
          "/rooms/#{room}/context/#{event}",
          params: { limit: limit }
        ).parsed_response
      end

      # Get the members of a room.
      #
      # @param room [String] The room to query.
      # @return [Array] An array of users that are in this room.
      def get_members(room)
        make_request(:get, "/rooms/#{room}/members")['chunk']
      end

      # Get a list of messages from a room.
      #
      # @param room [String] The room to get messages from.
      # @param from [String] Token to return events from.
      # @param direction ['b', 'f'] Direction to return events from.
      # @param limit [Fixnum] Maximum number of events to return.
      # @return [Hash] A hash containing the messages, as well as `start` and
      #   `end` tokens for pagination.
      def get_messages(room, from: 'START', to: 'END',
                       direction: 'b', limit: 10)
        make_request(
          :get,
          "/rooms/#{room}/messages",
          params: { from: from, to: to, dir: direction, limit: limit }
        ).parsed_response
      end

      # @overload get_room_state(room)
      #   Get state events for the current state of a room.
      #   @param room [String] The room to get events for.
      #   @return [Array] An array with state events for the room.
      # @overload get_room_state(room, type)
      #   Get the contents of a specific kind of state in the room.
      #   @param room [String] The room to get the data from.
      #   @param type [String] The type of state to get.
      #   @return [Hash] Information about the state type.
      # @overload get_room_state(room, type, key)
      #   Get the contents of a specific kind of state including only the
      #   specified key in the result.
      #   @param room [String] The room to get the data from.
      #   @param type [String] The type of state to get.
      #   @param key [String] The key of the state to look up.
      #   @return [Hash] Information about the requested state.
      def get_state(room, type = nil, key = nil)
        if type && key
          make_request(:get, "/rooms/#{room}/state/#{type}/#{key}")
            .parsed_response
        elsif type
          make_request(:get, "/rooms/#{room}/state/#{type}").parsed_response
        else
          make_request(:get, "/rooms/#{room}/state").parsed_response
        end
      end
    end
  end
end