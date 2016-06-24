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
        room.on(:message) { |r, s, m| broadcast(:room_message, r, s, m) }
        room.on(:notice) { |r, s, m| broadcast(:room_notice, r, s, m) }
        room.on(:emote) { |r, s, m| broadcast(:room_emote, r, s, m) }
      end
    end

    def start_syncing
      @sync_thread ||= Thread.new { loop { sync! } }
    end

    def stop_syncing
      return unless @sync_thread.is_a? Thread
      @sync_thread.exit
      @sync_thread.join
      @sync_thread = nil
    end

    def get_user(id)
      @users[id]
    end

    def get_room(id)
      @rooms[id]
    end

    private

    def sync!
      events = @matrix.sync since: @since
      process_sync events
    rescue ApiError => err
      broadcast(:sync_error, err)
    end

    def process_sync(events)
      return unless events.is_a? Hash
      @since = events['next_batch']
      broadcast(:sync, events)

      @rooms.process_events events['rooms'] if events.key? 'rooms'
    end
  end
end
