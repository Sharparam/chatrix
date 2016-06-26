require 'chatrix/matrix'
require 'chatrix/users'
require 'chatrix/rooms'

require 'wisper'

module Chatrix
  # A client wrapping the API in easy-to-use methods.
  class Client
    include Wisper::Publisher

    # @!attribute [r] me
    #   @return [User] The user associated with the access token.
    attr_reader :me

    # Initializes a new Client instance.
    #
    # Currently it requires a token, future versions will allow login
    # with arbitrary details.
    #
    # @param token [String] The access token to use.
    # @param id [String] The user ID of the token owner.
    # @param homeserver [String,nil] Homeserver to connect to. If not set,
    #   the default homeserver defined in Chatrix::Matrix will be used.
    def initialize(token, id, homeserver: nil)
      @matrix = Matrix.new token, homeserver

      @users = Users.new
      @rooms = Rooms.new @users, @matrix

      @me = @users.send(:get_user, id)

      @rooms.on(:added) do |room|
        broadcast(:room_added, room)
        room.timeline.on(:message) { |r, m| broadcast(:room_message, r, m) }
      end
    end

    # Starts syncing against the homeserver.
    #
    # Launches a new thread that will continously check for new events
    # from the server.
    #
    # @see #sync! See the documentation for {#sync!} for more information
    #   and what happens in case of an error during sync.
    def start_syncing
      @sync_thread ||= Thread.new { loop { sync! } }
    end

    # Stops syncing against the homeserver.
    def stop_syncing
      return unless @sync_thread.is_a? Thread
      @sync_thread.exit
      @sync_thread.join
      @sync_thread = nil
    end

    # Gets the user with the specified ID or display name.
    #
    # @return [User,nil] Returns a User object if the user could be found,
    #   otherwise `nil`.
    def get_user(id)
      @users[id]
    end

    # Gets the room with the specified ID, alias, or name.
    #
    # @return [Room,nil] Returns a Room object if the room could be found,
    #   otherwise `nil`.
    def get_room(id)
      @rooms[id]
    end

    private

    # Syncs against the server.
    #
    # If an API error occurs during sync, it will be rescued and broadcasted
    # as `:sync_error`.
    def sync!
      events = @matrix.sync since: @since
      process_sync events
    rescue ApiError => err
      broadcast(:sync_error, err)
    end

    # Process the sync result.
    #
    # @param events [Hash] The events to sync.
    def process_sync(events)
      return unless events.is_a? Hash
      @since = events['next_batch']
      broadcast(:sync, events)

      @rooms.process_events events['rooms'] if events.key? 'rooms'
    end
  end
end
