require 'chatrix/api/api_component'

module Chatrix
  module Api
    # Contains methods to use session related endpoints in the API.
    class Session < ApiComponent
      # Gets third-party IDs associated with the current account.
      # @return [Array] A list of 3rd party IDs.
      def threepids
        make_request(:get, '/account/3pid')['threepids']
      end

      # Adds third-party identification information to the user account.
      # @param data [Hash] The data to add. Refer to the official documentation
      #   for more information.
      # @return [Boolean] `true` if the information was added successfully,
      #   otherwise `false`.
      def add_threepid(data)
        make_request(:post, '/account/3pid', content: data).code == 200
      end

      # Set a new password for the current account.
      #
      # @note The server may request additional authentication as per the
      #   official documentation on the "User-Interactive Authentication API".
      #
      # @param password [String] The new password to set.
      # @param auth [Hash,nil] If provided, the hash will be passed in the
      #   request as additional parameters inside the `auth` field.
      # @return [Boolean] `true` if the password was successfully changed,
      #   otherwise `false`.
      def set_password(password, auth = nil)
        data = { new_password: password }
        data[:auth] = auth if auth

        make_request(:post, '/account/password', content: data).code == 200
      end

      # Registers a new user on the homeserver.
      #
      # @note On a successful registration, the
      #   {Matrix#access_token access_token} and `refresh_token` will be
      #   updated to the values returned by the server.
      #
      # @param data [Hash] Registration data. Populate this with the
      #   information needed to register the new user.
      #
      #   Refer to the official API documentation on how to populate the
      #   data hash.
      #
      # @param kind [String] The kind of registration to make.
      #   Either `'guest'` or `'user'`.
      #
      # @return [Hash] On success, returns a hash with information about the
      #   newly registered user. An example return value is given below.
      #
      #   ```ruby
      #   {
      #     'user_id' => '@foo:bar.org',
      #     'home_server' => 'https://bar.org',
      #     'access_token' => 'some secret token',
      #     'refresh_token' => 'refresh token here'
      #   }
      #   ```
      def register(data, kind = 'user')
        response = make_request(
          :post,
          '/register',
          params: { kind: kind },
          content: data
        )

        @matrix.access_token = response['access_token']
        @refresh_token = response['refresh_token']

        response.parsed_response
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
      def login(method, options)
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
      #   valid for further API calls.
      #
      # @return [Boolean] `true` if the user was successfully logged out,
      #   otherwise `false`.
      def logout
        response = make_request :post, '/logout'

        # A successful logout means the access token has been invalidated
        @matrix.access_token = nil

        response.code == 200
      end

      # Gets a new access token to use for API calls when the current one
      # expires.
      #
      # @note On success, the internal {Matrix#access_token access_token} and
      #   `refresh_token` will be updated automatically for use in
      #   subsequent API calls.
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
