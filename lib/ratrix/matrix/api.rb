require 'httparty'

module Ratrix::Matrix
class Ratrix::Matrix::API
    include HTTParty

    headers({
        'User-Agent' => "ratrix/#{Ratrix::VERSION}",
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
    })

    debug_output $stdout

    DEFAULT_ENDPOINT = 'https://matrix.org'

    DEFAULT_API_PATH = '/_matrix/client/r0'

    ##
    # Initializes a new instance of Ratrix::Matrix::API.
    #
    # Parameters:
    #   endpoint
    #     The API endpoint to use (homeserver).
    #
    #   api_path
    #     The API path is added between the endpoint and the request path.
    #
    #     Ex: <tt>https://matrix.org/_matrix/client/api/v1/initialSync</tt>
    #
    #     In the above example, <tt>https://matrix.org</tt> is the endpoint,
    #     <tt>/_matrix/client/api/v1</tt> is the API path, and
    #     <tt>/initialSync</tt> is the request path.
    #
    #   token
    #     The authorization token to use.
    def initialize(endpoint = DEFAULT_ENDPOINT, api_path = DEFAULT_API_PATH, token = nil)
        @endpoint = endpoint
        @api_path = api_path

        @base_uri = @endpoint + @api_path

        @transaction_id = 0

        return unless token

        @auth_token = token
    end

    ##
    # Sets the authorization token to use for requests.
    def auth_token=(token)
        @auth_token = token
    end

    ##
    # Gets the current authorization token in use.
    def auth_token
        @auth_token
    end

    def send_message_event(room, type, content)
        room = get_room_id room if room.start_with? '#'
        @transaction_id += 1
        make_request :put, "/rooms/#{room}/send/#{type}/#{@transaction_id}", content
    end

    def send_message(room, content, type = 'm.text')
        send_message_event room, 'm.room.message', { msgtype: type, body: content }
    end

    def get_room_id(room_alias)
        response = make_request :get, "/directory/room/#{room_alias}"

        case response.code
        when 200
            response['room_id']
        else
            nil
        end
    end

    private

    def make_request(method, path, content = {}, &block)
        path = @base_uri + URI::encode(path)
        options = { query: {access_token: @auth_token}, body: content.to_json }

        case method
        when :get
            self.class.get path, options, &block
        when :put
            self.class.put path, options, &block
        when :post
            self.class.post path, options, &block
        end
    end
end
end
