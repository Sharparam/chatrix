require 'chatrix/api/api_component'

module Chatrix
  module Api
    # Contains methods to use user endpoints in the API.
    class Users < ApiComponent
      # Gets information about a specific user.
      #
      # @param user [String] The user to query (`@user:host.tld`).
      # @return [Hash] The user information.
      # @raise [UserNotFoundError] If the user could not be found.
      #
      # @example Print a user's display name
      #   puts get_user('@foo:matrix.org')['displayname']
      def get(user)
        make_request(:get, "/profile/#{user}").parsed_response
      rescue NotFoundError
        raise UserNotFoundError.new(user),
              'The specified user could not be found'
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
        raise UserNotFoundError.new(user),
              'The specified user could not be found'
      end

      # Sets a new display name for a user.
      #
      # @note Can only be used on the user who possesses the
      #   {Matrix#access_token access_token} currently in use.
      #
      # @param user [String] The user to modify (`@user:host.tld`).
      # @param displayname [String] The new displayname to set.
      # @return [Boolean] `true` if the new display name was successfully set,
      #   otherwise `false`.
      def set_displayname(user, displayname)
        make_request(
          :put,
          "/profile/#{user}/displayname",
          content: { displayname: displayname }
        ).code == 200
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
      # @note Only the user for whom the {Matrix#access_token access_token} is
      #   valid for can have their presence updated.
      #
      # @param user [String] The user to update.
      # @param status [String] The new status to set. Eg. `'online'`
      #   or `'offline'`.
      # @param message [String,nil] If set,
      #   associates a message with the status.
      # @return [Boolean] `true` if the presence was updated successfully,
      #   otherwise `false`.
      def update_presence_status(user, status, message = nil)
        content = { presenceState: { presence: status } }

        content[:presenceState][:status_msg] = message if message

        make_request(:put, "/presence/#{user}/status", content: content)
          .code == 200
      end
    end
  end
end
