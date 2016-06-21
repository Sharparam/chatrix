require 'httparty'

class Ratrix::Matrix::API
    include HTTParty

    DEFAULT_ENDPOINT = 'https://matrix.org'

    DEFAULT_API_PATH = '/_matrix/client/api/v1'

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

        base_uri @endpoint + @api_path

        headers { 'User-Agent' => "ratrix/#{Ratrix::VERSION}" }

        return unless token

        auth_token = token
        default_params { auth_token: auth_token }
    end

    ##
    # Sets the authorization token to use for requests.
    def auth_token=(token)
        @auth_token = token
        default_params { auth_token: @auth_token }
    end

    ##
    # Gets the current authorization token in use.
    def auth_token
        @auth_token
    end

    def send_message_event(room, type, content)
        @@put "/rooms/#{room}/send/#{type}", content
    end

    def send_message(room, content, type = 'm.text')
        @send_message_event room, 'm.room.message', { msgtype: type, body: content }
    end
end
