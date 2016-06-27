require 'chatrix/errors'

require 'chatrix/api/session'
require 'chatrix/api/users'
require 'chatrix/api/rooms'
require 'chatrix/api/media'
require 'chatrix/api/push'

require 'httparty'

module Chatrix
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
  class Matrix
    include HTTParty

    headers('User-Agent' => "chatrix/#{Chatrix::VERSION}",
            'Content-Type' => 'application/json',
            'Accept' => 'application/json')

    # Maps HTTP methods to their respective HTTParty method.
    METHODS = {
      get: -> (path, options, &block) { get path, options, &block },
      put: -> (path, options, &block) { put path, options, &block },
      post: -> (path, options, &block) { post path, options, &block },
      delete: -> (path, options, &block) { delete path, options, &block }
    }.freeze

    # Registered request error handlers.
    ERROR_HANDLERS = {
      400 => [RequestError, 'Request failed'],
      401 => [AuthenticationError, 'Server requests additional authentication'],
      403 => [ForbiddenError, 'You do not have access to that resource'],
      404 => [NotFoundError, 'The resource was not found'],
      429 => [RateLimitError, 'The request was rate limited']
    }.tap do |h|
      h.default = [ApiError, 'An unknown API error occurred.']
    end.freeze

    # Default homeserver used if none is specified.
    DEFAULT_HOMESERVER = 'https://matrix.org'.freeze

    # API path used.
    API_PATH = '/_matrix/client/r0'.freeze

    # @return [String] the access token used when performing requests
    #   to the homeserver.
    attr_accessor :access_token

    # @return [String] the homeserver for this API object.
    attr_reader :homeserver

    # @return [Api::Session] the instance of Api::Session to perform
    #   session-related API calls with.
    attr_reader :session

    # @return [Api::Users] the instance of Api::Users to perform user-related
    #   API calls with.
    attr_reader :users

    # @return [Api::Rooms] the instance of Api::Rooms to perform room-related
    #   API calls with.
    attr_reader :rooms

    # @return [Api::Media] the instance of Api::Media to perform media-related
    #   API calls with.
    attr_reader :media

    # @return [Api::Push] the instance of Api::Push to perform push-related
    #   API calls with.
    attr_reader :push

    # Initializes a new instance of Matrix.
    #
    # @param token [String] The access token to use.
    # @param homeserver [String] The homeserver to make requests to.
    def initialize(token = nil, homeserver = DEFAULT_HOMESERVER)
      @homeserver = homeserver
      @base_uri = @homeserver + API_PATH
      @access_token = token

      @session = Api::Session.new self
      @users = Api::Users.new self
      @rooms = Api::Rooms.new self
      @media = Api::Media.new self
      @push = Api::Push.new self
    end

    # Gets supported API versions from the server.
    # @return [Array<String>] an array with the supported versions.
    def versions
      make_request(
        :get, '/versions',
        base: "#{@homeserver}/_matrix/client"
      )['versions']
    end

    # Performs a whois lookup on the specified user.
    # @param user [String] The user to look up.
    # @return [Hash] Information about the user.
    def whois(user)
      make_request(:get, "/admin/whois/#{user}").parsed_response
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
      options[:filter] = parse_filter filter

      make_request(:get, '/sync', params: options).parsed_response
    end

    # Gets the definition for a filter.
    # @param user [String] The user that has the filter.
    # @param filter [String] The ID of the filter to get.
    # @return [Hash] The filter definition.
    def get_filter(user, filter)
      make_request(:get, "/user/#{user}/filter/#{filter}").parsed_response
    end

    # Uploads a filter to the server.
    # @param user [String] The user to upload the filter as.
    # @param filter [Hash] The filter definition.
    # @return [String] The ID of the created filter.
    def create_filter(user, filter)
      make_request(:post, "/user/#{user}/filter", content: filter)['filter_id']
    end

    # Performs a full text search on the server.
    # @param from [String] Where to return events from, if given. This can be
    #   obtained from previous calls to {#search}.
    # @param options [Hash] Search options, see the official documentation
    #   for details on how to structure this.
    # @return [Hash] the search results.
    def search(from: nil, options: {})
      make_request(
        :post, '/search',
        params: { next_batch: from }, content: options
      ).parsed_response
    end

    # Helper method for performing requests to the homeserver.
    #
    # @param method [Symbol] HTTP request method to use. Use only symbols
    #   available as keys in {METHODS}.
    # @param path [String] The API path to query, relative to the base
    #   API path, eg. `/login`.
    # @param opts [Hash] Additional request options.
    #
    # @option opts [Hash] :params Additional parameters to include in the
    #   query string (part of the URL, not put in the request body).
    # @option opts [Hash,#read] :content Content to put in the request body.
    #   If set, must be a Hash or a stream object.
    # @option opts [Hash{String => String}] :headers Additional headers to
    #   include in the request.
    # @option opts [String,nil] :base If this is set, it will be used as the
    #   base URI for the request instead of the default (`@base_uri`).
    #
    # @yield [fragment] HTTParty will call the block during the request.
    #
    # @return [HTTParty::Response] The HTTParty response object.
    def make_request(method, path, opts = {}, &block)
      path = (opts[:base] || @base_uri) + URI.encode(path)
      options = make_options opts[:params], opts[:content], opts[:headers]

      parse_response METHODS[method].call(path, options, &block)
    end

    private

    # Create an options Hash to pass to a server request.
    #
    # This method embeds the {#access_token access_token} into the
    # query parameters.
    #
    # @param params [Hash{String=>String},nil] Query parameters to add to
    #   the options hash.
    # @param content [Hash,#read,nil] Request content. Can be a hash,
    #   stream, or `nil`.
    # @return [Hash] Options hash ready to be passed into a server request.
    def make_options(params, content, headers = {})
      { headers: headers }.tap do |o|
        o[:query] = @access_token ? { access_token: @access_token } : {}
        o[:query].merge!(params) if params.is_a? Hash
        o.merge! make_body content
      end
    end

    # Create a hash with body content based on the type of `content`.
    # @param content [Hash,#read,Object] Some kind of content to put into
    #   the request body. Can be a Hash, stream object, or other kind of
    #   object.
    # @return [Hash{Symbol => Object}] A hash with the relevant body key
    #   and value.
    def make_body(content)
      key = content.respond_to?(:read) ? :body_stream : :body
      value = content.is_a? Hash ? content.to_json : content
      { key => value }
    end

    # Parses a HTTParty Response object and returns it if it was successful.
    #
    # @param response [HTTParty::Response] The response object to parse.
    # @return [HTTParty::Response] The same response object that was passed
    #   in, if the request was successful.
    #
    # @raise [RequestError] If a `400` response code was returned from the
    #   request.
    # @raise [AuthenticationError] If a `401` response code was returned
    #   from the request.
    # @raise [ForbiddenError] If a `403` response code was returned from the
    #   request.
    # @raise [NotFoundError] If a `404` response code was returned from the
    #   request.
    # @raise [RateLimitError] If a `429` response code was returned from the
    #   request.
    # @raise [ApiError] If an unknown response code was returned from the
    #   request.
    def parse_response(response)
      case response.code
      when 200 # OK
        response
      else
        handler = ERROR_HANDLERS[response.code]
        raise handler.first.new(response.parsed_response), handler.last
      end
    end

    # Parses a filter object for use in a query string.
    # @param filter [String,Hash] The filter object to parse.
    # @return [String] Query-friendly filter object. Or the `filter`
    #   parameter as-is if it failed to parse.
    def parse_filter(filter)
      filter.is_a?(Hash) ? URI.encode(filter.to_json) : filter
    end
  end
end
