require 'ratrix/errors'

require 'httparty'

module Ratrix
  # Provides an interface to the Matrix API on a homeserver.
  #
  # Detailed information about the data structures is not included here and
  # can be found on the
  # {http://matrix.org/docs/api/client-server Matrix API page}.
  #
  # @note Any of the methods may raise the errors listed in {#parse_response}.
  #   Consider this when calling the methods.
  # @note Endpoints that require a room ID in the official API can be passed
  #   a room alias in this implementation, the room ID will be automatically
  #   looked up from the homeserver.
  #
  # @todo Try to extract functionality to make this class smaller.
  #
  # rubocop:disable ClassLength
  class Matrix
    include HTTParty

    headers('User-Agent' => "ratrix/#{Ratrix::VERSION}",
            'Content-Type' => 'application/json',
            'Accept' => 'application/json')

    # Maps HTTP methods to their respective HTTParty method.
    METHODS = {
      get: -> (path, options, &block) { get path, options, &block },
      put: -> (path, options, &block) { put path, options, &block },
      post: -> (path, options, &block) { post path, options, &block },
      delete: -> (path, options, &block) { delete path, options, &block }
    }.freeze

    # Default homeserver used if none is specified.
    DEFAULT_HOMESERVER = 'https://matrix.org'.freeze

    # API path used.
    API_PATH = '/_matrix/client/r0'.freeze

    # @!attribute access_token
    #   @return [String] The access token used when performing requests
    #     to the homeserver.
    attr_accessor :access_token

    # @!attribute [r] homeserver
    #   @return [String] The homeserver for this API object.
    attr_reader :homeserver

    # Initializes a new instance of Ratrix::Matrix.
    #
    # @param token [String] The access token to use.
    # @param homeserver [String] The homeserver to make requests to.
    def initialize(token = nil, homeserver = DEFAULT_HOMESERVER)
      @homeserver = homeserver
      @base_uri = @homeserver + API_PATH
      @transaction_id = 0
      @access_token = token
    end

    # Gets third-party IDs associated with the current account.
    #
    # @return [Array] A list of 3rd party IDs.
    def threepids
      make_request(:get, '/account/3pid')['threepids']
    end

    # Gets information about a specific user.
    #
    # @param user [String] The user to query (`@user:host.tld`).
    # @return [Hash] The user information.
    # @raise [UserNotFoundError] If the user could not be found.
    #
    # @example Print a user's display name
    #   puts get_user('@foo:matrix.org')['displayname']
    def get_user(user)
      make_request(:get, "/profile/#{user}").parsed_response
    rescue NotFoundError
      raise UserNotFoundError.new(user), 'The specified user could not be found'
    end

    # Get the URL to a user's avatar (an `mxp://` URL).
    #
    # @param (see #get_user)
    # @return [String] The avatar URL.
    # @raise [AvatarNotFoundError] If the avatar or user could not be found.
    def get_avatar(user)
      make_request(:get, "/profile/#{user}/avatar_url")['avatar_url']
    rescue NotFoundError
      raise AvatarNotFoundError.new(user), 'Avatar or user could not be found'
    end

    # Get a user's display name (**not** username).
    #
    # @param (see #get_user)
    # @raise (see #get_user)
    def get_displayname(user)
      make_request(:get, "/profile/#{user}/displayname")['displayname']
    rescue NotFoundError
      raise UserNotFoundError.new(user), 'The specified user could not be found'
    end

    # Sets a new display name for a user.
    #
    # @note Can only be used on the user who possesses the
    #   {#access_token access_token} currently in use.
    #
    # @param user [String] The user to modify (`@user:host.tld`).
    # @param displayname [String] The new displayname to set.
    # @return [Boolean] `true` if the new display name was successfully set,
    #   otherwise `false`.
    def set_displayname(user, displayname)
      make_request(
        :put,
        "/profile/#{user}/displayname",
        content: {
          displayname: displayname
        }
      ).code == 200
    end

    # Get tags that a specific user has set on a room.
    #
    # @param user [String] The user whose settings to retrieve
    #   (`@user:host.tld`).
    # @param room [String] The room to get tags from (ID or alias).
    # @return [Hash{String=>Hash}] A hash with tag data. The tag name is
    #   the key and any additional metadata is contained in the Hash value.
    def get_user_room_tags(user, room)
      room = get_room_id room if room.start_with? '#'
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
    def get_room_alias_info(room_alias)
      make_request(:get, "/directory/room/#{room_alias}").parsed_response
    rescue NotFoundError
      raise RoomNotFoundError.new(room_alias),
            'The specified room alias could not be found'
    end

    # Get a room's ID from its alias.
    #
    # @param room_alias [String] The room alias to query.
    # @return [String] The actual room ID for the room.
    def get_room_id(room_alias)
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
      room = get_room_id room if room.start_with? '#'
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
    def get_room_members(room)
      room = get_room_id room if room.start_with? '#'
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

    # Sends a message object to a room.
    #
    # @param room [String] The room to send to.
    # @param content [Hash] The message content to send.
    # @param type [String] The type of message to send.
    # @return [String] The event ID of the sent message is returned.
    # @see #send_message_type
    # @see #send_message
    # @see #send_emote
    # @see #send_notice
    # @see #send_html
    def send_message_raw(room, content, type = 'm.room.message')
      room = get_room_id room if room.start_with? '#'
      @transaction_id += 1
      make_request(
        :put,
        "/rooms/#{room}/send/#{type}/#{@transaction_id}",
        content: content
      )['event_id']
    end

    # A helper method to send a simple message construct.
    #
    # @param room [String] The room to send the message to.
    # @param content [String] The message to send.
    # @param type [String] The type of message this is.
    # @return (see #send_message_raw)
    # @see #send_message
    # @see #send_notice
    # @see #send_emote
    # @see #send_html
    def send_message_type(room, content, type = 'm.text')
      send_message_raw room, msgtype: type, body: content
    end

    # Sends a plaintext message to a room.
    #
    # @param room [String] The room to send to.
    # @param content [String] The message to send.
    # @return (see #send_message_raw)
    #
    # @example Sending a simple message
    #   send_message('#party:matrix.org', 'Hello everyone!')
    def send_message(room, content)
      send_message_type room, content
    end

    # Sends a notice message to a room.
    #
    # @param room [String] The room to send to.
    # @param content [String] The message to send.
    # @return (see #send_message_raw)
    #
    # @example Sending a notice
    #   send_notice('#stuff:matrix.org', 'This is a notice')
    def send_notice(room, content)
      send_message_type room, content, 'm.notice'
    end

    # Sends an emote to a room.
    #
    # `/me <message here>`
    #
    # @param room [String] The room to send to.
    # @param content [String] The emote to send.
    # @return (see #send_message_raw)
    #
    # @example Sending an emote
    #   # Will show up as: "* <user> is having fun"
    #   send_emote('#party:matrix.org', 'is having fun')
    def send_emote(room, content)
      send_message_type room, content, 'm.emote'
    end

    # Sends a message formatted using HTML markup.
    #
    # The `body` field in the content will have the HTML stripped out, and is
    # usually presented in clients that don't support the formatting.
    #
    # The `formatted_body` field in the content will contain the actual HTML
    # formatted message (as passed to the `html` parameter).
    #
    # @param room [String] The room to send to.
    # @param html [String] The HTML formatted text to send.
    # @return (see #send_message_raw)
    #
    # @example Sending an HTML message
    #   send_html('#html:matrix.org', '<strong>Hello</strong> <em>world</em>!')
    def send_html(room, html)
      send_message_raw(
        room,
        msgtype: 'm.text',
        format: 'org.matrix.custom.html',
        body: html.gsub(%r{</?[^>]*?>}, ''), # TODO: Make this better
        formatted_body: html
      )
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

    # Sends a message to the server informing it about a user having started
    # or stopped typing.
    #
    # @param room [String] The affected room.
    # @param user [String] The user that started or stopped typing.
    # @param typing [Boolean] Whether the user is typing.
    # @param duration [Fixnum] How long the user will be typing for
    #   (in milliseconds).
    # @return [Boolean] `true` if the message sent successfully, otherwise
    #   `false`.
    def send_typing(room, user, typing = true, duration = 30_000)
      room = get_room_id room if room.start_with? '#'

      content = { typingState: { typing: typing, timeout: duration } }

      make_request(
        :put,
        "/rooms/#{room}/typing/#{user}",
        content: content
      ).code == 200
    end

    # Synchronize with the latest state on the server.
    #
    # For initial sync, call this method with the `since` parameter
    # set to `nil`.
    #
    # @param filter [String,Hash] The ID of a filter to use, or provided
    #   directly as a hash.
    # @param since [String,nil] A point in time to continue sync from.
    #   Will retrieve a snapshot of the state if not set, which will also
    #   provide a `next_batch` value to use for `since` in the next call.
    # @param full_state [Boolean] If `true`, all state events will be returned
    #   for all rooms the user is a member of.
    # @param set_presence [Boolean] If `true`, the user performing this request
    #   will have their presence updated to show them as being online.
    # @param timeout [Fixnum] Maximum time (in milliseconds) to wait before
    #   the request is aborted.
    # @return [Hash] The initial snapshot of the state (if no `since` value
    #   was provided), or a delta to use for updating state.
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

    # Joins a room on the homeserver.
    #
    # @param room [String] The room to join.
    # @param third_party_signed [Hash,nil] If provided, the homeserver must
    #   verify that it matches a pending `m.room.third_party_invite` event in
    #   the room, and perform key validity checking if required by the event.
    # @return [String] The ID of the room that was joined is returned.
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

    # Kicks and bans a user from a room.
    #
    # @param room [String] The room to ban the user from.
    # @param user [String] The user to ban.
    # @param reason [String] Reason why the ban was made.
    # @return [Boolean] `true` if the ban was carried out successfully,
    #   otherwise `false`.
    #
    # @example Banning a spammer
    #   ban('#haven:matrix.org', '@spammer:spam.com', 'Spamming the room')
    def ban(room, user, reason)
      room = get_room_id room if room.start_with? '#'
      make_request(
        :post,
        "/rooms/#{room}/ban",
        content: { reason: reason, user_id: user }
      ).code == 200
    end

    # Forgets about a room.
    #
    # @param room [String] The room to forget about.
    # @return [Boolean] `true` if the room was forgotten successfully,
    #   otherwise `false`.
    def forget(room)
      room = get_room_id room if room.start_with? '#'
      make_request(:post, "/rooms/#{room}/forget").code == 200
    end

    # Kicks a user from a room.
    #
    # This does not ban the user, they can rejoin unless the room is
    # invite-only, in which case they need a new invite to join back.
    #
    # @param room [String] The room to kick the user from.
    # @param user [String] The user to kick.
    # @param reason [String] The reason for the kick.
    # @return [Boolean] `true` if the user was successfully kicked,
    #   otherwise `false`.
    #
    # @example Kicking an annoying user
    #   kick('#fun:matrix.org', '@anon:4chan.org', 'Bad cropping')
    def kick(room, user, reason)
      room = get_room_id room if room.start_with? '#'
      make_request(
        :post,
        "/rooms/#{room}/kick",
        content: { reason: reason, user_id: user }
      ).code == 200
    end

    # Leaves a room (but does not forget about it).
    #
    # @param room [String] The room to leave.
    # @return [Boolean] `true` if the room was left successfully,
    #   otherwise `false`.
    def leave(room)
      room = get_room_id room if room.start_with? '#'
      make_request(:post, "/rooms/#{room}/leave").code == 200
    end

    # Unbans a user from a room.
    #
    # @param room [String] The room to unban the user from.
    # @param user [String] The user to unban.
    # @return [Boolean] `true` if the user was successfully unbanned,
    #   otherwise `false`.
    def unban(room, user)
      room = get_room_id room if room.start_with? '#'
      make_request(
        :post,
        "/rooms/#{room}/unban",
        content: { user_id: user }
      ).code == 200
    end

    # Performs a login attempt.
    #
    # @note A successful login will update the {#access_token access_token}
    #   to the new one returned from the login response.
    #
    # @param method [String] The method to use for logging in.
    #   For user/password combination, this should be `m.login.password`.
    # @param options [Hash{String=>String}] Options to pass for logging in.
    #   For a password login, this should contain a key `:user` for the
    #   username, and a key `:password` for the password.
    # @return [Hash] The response from the server. A successful login will
    #   return a hash containing the user id, access token, and homeserver.
    #
    # @example Logging in with username and password
    #   login('m.login.password', user: '@snoo:reddit.com', password: 'hunter2')
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

    # Logs out.
    #
    # @note This will **invalidate the access token**. It will no longer be
    #   valid for API calls.
    #
    # @return [Hash] The response from the server (an empty hash).
    def logout
      response = make_request :post, '/logout'

      # A successful logout means the access token has been invalidated
      @access_token = nil

      response.parsed_response
    end

    # Gets a new access token to use for API calls when the current one
    # expires.
    #
    # @note On success, the internal {#access_token access_token} will be
    #   updated automatically for use in subsequent API calls.
    #
    # @param token [String,nil] The `refresh_token` to provide for the server
    #   when requesting a new token. If not set, the internal refresh and
    #   access tokens will be used.
    # @return [Hash] The response hash from the server will contain the new
    #   access token and a refresh token to use the next time a new access
    #   token is needed.
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

    # Gets the presence list for a user.
    #
    # @param user [String] The user whose list to get.
    # @return [Array] A list of presences for this user.
    #
    # @todo The official documentation on this endpoint is weird, what does
    #   this really do?
    def get_presence_list(user)
      make_request(:get, "/presence/list/#{user}").parsed_response
    end

    # Adds or removes users from a user's presence list.
    #
    # @param user [String] The user whose list to modify.
    # @param data [Hash{String=>Array<String>}] Contains two arrays,
    #   `invite` and `drop`. Users listed in the `invite` array will be
    #   invited to join the presence list. Users listed in the `drop` array
    #   will be removed from the presence list.
    #   Note that both arrays are not required but at least one must be
    #   present.
    # @return [Boolean] `true` if the list was successfully updated,
    #   otherwise `false`.
    #
    # @example Add and remove two users
    #   update_presence_list(
    #     '@me:home.org',
    #     {
    #       invite: ['@friend:home.org'],
    #       drop: ['@enemy:other.org']
    #     }
    #   )
    def update_presence_list(user, data)
      make_request(
        :post,
        "/presence/list/#{user}",
        content: { presence_diff: data }
      ).code == 200
    end

    # Gets the presence status of a user.
    #
    # @param user [String] The user to query.
    # @return [Hash] Hash with information about the user's presence,
    #   contains information indicating if they are available and when
    #   they were last active.
    def get_presence_status(user)
      make_request(:get, "/presence/#{user}/status").parsed_response
    end

    # Updates the presence status of a user.
    #
    # @note Only the user for whom the {#access_token access_token} is
    #   valid for can have their presence updated.
    #
    # @param user [String] The user to update.
    # @param status [String] The new status to set. Eg. `'online'`
    #   or `'offline'`.
    # @param message [String,nil] If set, associates a message with the status.
    # @return [Boolean] `true` if the presence was updated successfully,
    #   otherwise `false`.
    def update_presence_status(user, status, message = nil)
      content = { presenceState: { presence: status } }

      content[:presenceState][:status_msg] = message if message

      make_request(
        :put,
        "/presence/#{user}/status",
        content: content
      ).code == 200
    end

    # Get the list of public rooms on the server.
    #
    # The `start` and `end` values returned in the result can be passed to
    # `from` and `to`, for pagination purposes.
    #
    # @param from [String] The stream token to start looking from.
    # @param to [String] The stream token to stop looking at.
    # @param limit [Fixnum] Maximum number of results to return in one request.
    # @param direction ['f', 'b'] Direction to look in.
    # @return [Hash] Hash containing the list of rooms (in the `chunk` value),
    #   and pagination parameters `start` and `end`.
    def rooms(from: 'START', to: 'END', limit: 10, direction: 'b')
      make_request(
        :get,
        '/publicRooms',
        params: {
          from: start,
          to: to,
          limit: limit,
          dir: direction
        }
      ).parsed_response
    end

    private

    # Create an options Hash to pass to a server request.
    #
    # This method embeds the {#access_token access_token} into the
    # query parameters.
    #
    # @param params [Hash{String=>String},nil] Query parameters to add to
    #   the options hash.
    # @param content [Hash,nil] Request content to add to the options hash.
    # @return [Hash] Options hash ready to be passed into a server request.
    def make_request_options(params, content)
      options = {
        query: @access_token ? { access_token: @access_token } : {}
      }

      options[:query].merge!(params) if params.is_a? Hash
      options[:body] = content.to_json if content.is_a? Hash

      options
    end

    # Helper method for performing requests to the homeserver.
    #
    # @param method [Symbol] HTTP request method to use. Use only symbols
    #   available as keys in {METHODS}.
    # @param path [String] The API path to query, relative to the base
    #   API path, eg. `/login`.
    # @param params [Hash{String=>String}] Additional parameters to include
    #   in the query string (part of the URL, not put in the request body).
    # @param content [Hash] Content to put in the request body, must
    #   be serializable to json via `#to_json`.
    # @yield [fragment] HTTParty will call the block during the request.
    #
    # @return [HTTParty::Response] The HTTParty response object.
    def make_request(method, path, params: nil, content: nil, &block)
      path = @base_uri + URI.encode(path)
      options = make_request_options params, content

      parse_response METHODS[method].call(path, options, &block)
    end

    # Parses a HTTParty Response object and returns it if it was successful.
    #
    # @param response [HTTParty::Response] The response object to parse.
    # @return [HTTParty::Response] The same response object that was passed
    #   in, if the request was successful.
    #
    # @raise [ForbiddenError] If a `403` response code was returned from the
    #   request.
    # @raise [NotFoundError] If a `404` response code was returned from the
    #   request.
    # @raise [RequestError] If an error object was returned from the server.
    # @raise [ApiError] If an unparsable error was returned from the server.
    #
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
