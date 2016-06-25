require 'chatrix/api/api_component'

module Chatrix
  module Api
    # Contains methods to use session related endpoints in the API.
    class Session < ApiComponent
      # Initializes a new Session instance.
      # @param matrix [Matrix] The matrix API instance.
      def initialize(matrix)
        super
      end

      # Gets third-party IDs associated with the current account.
      #
      # @return [Array] A list of 3rd party IDs.
      def threepids
        make_request(:get, '/account/3pid')['threepids']
      end

      # Performs a login attempt.
      #
      # @note A successful login will update the
      #   {Matrix#access_token access_token} to the new one returned from
      #   the login response.
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
      #   login('m.login.password',
      #         user: '@snoo:reddit.com', password: 'hunter2')
      def login(method, options = {})
        response = make_request(
          :post,
          '/login',
          content: { type: method }.merge!(options)
        )

        # Update the local access token
        @matrix.access_token = response['access_token']

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
        @matrix.access_token = nil

        response.parsed_response
      end

      # Gets a new access token to use for API calls when the current one
      # expires.
      #
      # @note On success, the internal {Matrix#access_token access_token} will
      #   be updated automatically for use in subsequent API calls.
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

        @matrix.access_token = response['access_token']
        @refresh_token = response['refresh_token']

        response.parsed_response
      end
    end
  end
end
