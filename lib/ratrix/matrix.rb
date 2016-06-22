require 'ratrix/errors'

require 'httparty'

module Ratrix
  # Provides an interface to the Matrix API on a homeserver.
  # rubocop:disable ClassLength
  class Matrix
    include HTTParty

    headers('User-Agent' => "ratrix/#{Ratrix::VERSION}",
            'Content-Type' => 'application/json',
            'Accept' => 'application/json')

    METHODS = {
      get: -> (path, options, &block) { get path, options, &block },
      put: -> (path, options, &block) { put path, options, &block },
      post: -> (path, options, &block) { post path, options, &block },
      delete: -> (path, options, &block) { delete path, options, &block }
    }.freeze

    # Default homeserver used if none is specified.
    DEFAULT_HOMESERVER = 'https://matrix.org'.freeze

    # Default API path used if none is specified.
    DEFAULT_API_PATH = '/_matrix/client/r0'.freeze

    attr_accessor :access_token

    # Initializes a new instance of Ratrix::Matrix::API.
    #
    # @param homeserver [String] The API endpoint to use (homeserver).
    # @param token [String] The access token to use.
    # @param api_path [String]
    #   The API path is added between the endpoint and the request path.
    #
    #   Ex: `https://matrix.org/_matrix/client/api/v1/initialSync`
    #
    #   In the above example, `https://matrix.org` is the endpoint,
    #   `/_matrix/client/api/v1` is the API path, and
    #   `/initialSync` is the request path.
    def initialize(
      homeserver = DEFAULT_HOMESERVER,
      token = nil,
      api_path = DEFAULT_API_PATH
    )
      @homeserver = endpoint
      @api_path = api_path
      @base_uri = @homeserver + @api_path
      @transaction_id = 0
      @access_token = token
    end

    def threepids
      make_request(:get, '/account/3pid')['threepids']
    end

    def get_user(user)
      make_request(:get, "/profile/#{user}").parsed_response
    rescue NotFoundError
      raise UserNotFoundError.new(user), 'The specified user could not be found'
    end

    def get_avatar(user)
      make_request(:get, "/profile/#{user}/avatar_url")['avatar_url']
    rescue NotFoundError
      raise AvatarNotFoundError.new(user), 'Avatar or user could not be found'
    end

    def get_displayname(user)
      make_request(:get, "/profile/#{user}/displayname")['displayname']
    rescue NotFoundError
      raise UserNotFoundError.new(user), 'The specified user could not be found'
    end

    def set_displayname(user, displayname)
      make_request(
        :put,
        "/profile/#{user}/displayname",
        content: {
          displayname: displayname
        }
      ).code == 200
    end

    def get_user_room_tags(user, room)
      make_request(:get, "/user/#{user}/rooms/#{room}/tags")['tags']
    end

    def get_room_alias_info(room_alias)
      make_request(:get, "/directory/room/#{room_alias}").parsed_response
    rescue NotFoundError
      raise RoomNotFoundError.new(room_alias),
            'The specified room alias could not be found'
    end

    def get_room_id(room_alias)
      get_room_alias_info(room_alias)['room_id']
    end

    def get_event_context(room, event, limit = 10)
      room = get_room_id room if room.start_with? '#'
      make_request(
        :get,
        "/rooms/#{room}/context/#{event}",
        params: { limit: limit }
      ).parsed_response
    end

    def get_room_members(room)
      room = get_room_id room if room.start_with? '#'
      make_request(:get, "/rooms/#{room}/members")['chunk']
    end

    def get_room_messages(room, from, direction, limit = 10)
      room = get_room_id room if room.start_with? '#'
      make_request(
        :get,
        "/rooms/#{room}/messages",
        params: {
          from: from,
          dir: direction,
          limit: limit
        }
      ).parsed_response
    end

    def send_message_raw(room, content, type = 'm.room.message')
      room = get_room_id room if room.start_with? '#'
      @transaction_id += 1
      make_request(
        :put,
        "/rooms/#{room}/send/#{type}/#{@transaction_id}",
        content: content
      )['event_id']
    end

    def send_message_type(room, content, type = 'm.text')
      send_message_raw room, msgtype: type, body: content
    end

    def send_message(room, content)
      send_message_type room, content
    end

    def send_notice(room, content)
      send_message_type room, content, 'm.notice'
    end

    def send_emote(room, content)
      send_message_type room, content, 'm.emote'
    end

    def send_html(room, html)
      send_message_raw(
        room,
        msgtype: 'm.text',
        format: 'org.matrix.custom.html',
        body: html.gsub(%r{</?[^>]*?>}, ''), # TODO: Make this better
        formatted_body: html
      )
    end

    def get_room_state(room, type = nil, key = nil)
      room = get_room_id room if room.start_with? '#'

      if type && key
        make_request(
          :get,
          "/rooms/#{room}/state/#{type}/#{key}"
        ).parsed_response
      elsif type
        make_request(:get, "/rooms/#{room}/state/#{type}").parsed_response
      else
        make_request(:get, "/rooms/#{room}/state").parsed_response
      end
    end

    def send_typing(room, user, typing = true, duration = 30_000)
      room = get_room_id room if room.start_with? '#'

      content = { typingState: { typing: typing, timeout: duration } }

      make_request(
        :put,
        "/rooms/#{room}/typing/#{user}",
        content: content
      ).code == 200
    end

    def sync(filter: nil, since: nil, full_state: false,
             set_presence: true, timeout: 30_000)
      options = { full_state: full_state }

      options[:since] = since if since
      options[:set_presence] = 'offline' unless set_presence
      options[:timeout] = timeout if timeout

      if filter.is_a? Integer
        options[:filter] = filter
      elsif filter.is_a? Hash
        options[:filter] = URI.encode filter.to_json
      end

      make_request(:get, '/sync', params: options).parsed_response
    end

    def join(room, third_party_signed = nil)
      if third_party_signed
        make_request(
          :post,
          "/join/#{room}",
          content: { third_party_signed: third_party_signed }
        )['room_id']
      else
        make_request(:post, "/join/#{room}")['room_id']
      end
    end

    def ban(room, user, reason)
      room = get_room_id room if room.start_with? '#'
      make_request(
        :post,
        "/rooms/#{room}/ban",
        content: { reason: reason, user_id: user }
      ).code == 200
    end

    def forget(room)
      room = get_room_id room if room.start_with? '#'
      make_request(:post, "/rooms/#{room}/forget").code == 200
    end

    def kick(room, user, reason)
      room = get_room_id room if room.start_with? '#'
      make_request(
        :post,
        "/rooms/#{room}/kick",
        content: { reason: reason, user_id: user }
      ).code == 200
    end

    def leave(room)
      room = get_room_id room if room.start_with? '#'
      make_request(:post, "/rooms/#{room}/leave").code == 200
    end

    def unban(room, user)
      room = get_room_id room if room.start_with? '#'
      make_request(
        :post,
        "/rooms/#{room}/unban",
        content: { user_id: user }
      ).code == 200
    end

    def login(method, options = {})
      response = make_request(
        :post,
        '/login',
        content: { type: method }.merge!(options)
      )

      # Update the local access token
      @access_token = response['access_token']

      response.parsed_response
    end

    def logout
      response = make_request :post, '/logout'

      # A successful logout means the access token has been invalidated
      @access_token = nil

      response.parsed_response
    end

    def refresh(token = nil)
      refresh_token = token || @refresh_token || @access_token

      response = make_request(
        :post,
        '/tokenrefresh',
        content: { refresh_token: refresh_token }
      )

      @access_token = response['access_token']
      @refresh_token = response['refresh_token']

      response.parsed_response
    end

    def get_presence_list(user)
      make_request(:get, "/presence/list/#{user}").parsed_response
    end

    def update_presence_list(user, data = {})
      make_request(
        :post,
        "/presence/list/#{user}",
        content: { presence_diff: data }
      ).code == 200
    end

    def get_presence_status(user)
      make_request(:get, "/presence/#{user}/status").parsed_response
    end

    def update_presence_status(user, status, message = nil)
      content = { presenceState: { presence: status } }

      content[:presenceState][:status_msg] = message if message

      make_request(
        :put,
        "/presence/#{user}/status",
        content: content
      ).code == 200
    end

    def rooms
      make_request(:get, '/publicRooms').parsed_response
    end

    private

    def make_request_options(params, content)
      options = {
        query: @access_token ? { access_token: @access_token } : {}
      }

      options[:query].merge!(params) if params.is_a? Hash
      options[:body] = content.to_json if content.is_a? Hash

      options
    end

    def make_request(method, path, params: nil, content: nil, &block)
      path = @base_uri + URI.encode(path)
      options = make_request_options params, content

      parse_response METHODS[method].call(path, options, &block)
    end

    # rubocop:disable MethodLength
    def parse_response(response)
      case response.code
      when 200 # OK
        response
      when 403 # Forbidden
        raise ForbiddenError, 'You do not have access to that resource'
      when 404 # Not found
        raise NotFoundError, 'The specified resource could not be found'
      else
        if %w{(errcode), (error)}.all? { |k| response.include? k }
          raise RequestError.new(response.parsed_response), 'Request failed'
        end

        raise ApiError, 'Unknown API error occurred when carrying out request'
      end
    end
  end
end
