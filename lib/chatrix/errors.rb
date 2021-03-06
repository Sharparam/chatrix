# encoding: utf-8
# frozen_string_literal: true

module Chatrix
  # Generic faults from the library.
  class ChatrixError < StandardError
  end

  # Errors that stem from an API call.
  class ApiError < ChatrixError
    # @return [Hash] the raw error response object.
    attr_reader :error

    # @return [String] the type of error. `'E_UNKNOWN'` if the server
    #   did not give an error code.
    attr_reader :code

    # @return [String] the error message returned from the server.
    #   `'Unknown error'` if the server did not give any message.
    attr_reader :api_message

    # Initializes a new RequestError instance.
    # @param error [Hash{String=>String}] The error response object.
    def initialize(error = {})
      @error = error
      @code = error['errcode'] || 'E_UNKNOWN'
      @api_message = error['error'] || 'Unknown error'
    end
  end

  # Error raised when a request is badly formatted.
  class RequestError < ApiError
  end

  # Error raised when the API request limit is reached.
  class RateLimitError < ApiError
    # @return [Fixnum,nil] number of milliseconds to wait before attempting
    #   this request again. If no delay was provided this will be `nil`.
    attr_reader :retry_delay

    # Initializes a new RateLimitError instance.
    # @param error [Hash] The error response object.
    def initialize(error = {})
      super
      @retry_delay = error['retry_after_ms'] if error.key? 'retry_after_ms'
    end
  end

  # Raised when a resource is requested that the user does not have access to.
  class ForbiddenError < ApiError
  end

  # Raised when a resource is not found.
  class NotFoundError < ApiError
  end

  # Raised when a user is not found.
  class UserNotFoundError < NotFoundError
    # @return [String] the name of the user that was not found.
    attr_reader :username

    # Initializes a new UserNotFoundError instance.
    # @param username [String] The user that wasn't found.
    # @param error [Hash] The error response from the server.
    def initialize(username, error = {})
      super error
      @username = username
    end
  end

  # Raised when a user's avatar is not found.
  class AvatarNotFoundError < NotFoundError
    # @return [String] the user whose avatar was not found.
    attr_reader :username

    # Initializes a new AvatarNotFoundError instance.
    # @param username [String] Name of the user whose avatar was not found.
    # @param error [Hash] The error response from the server.
    def initialize(username, error = {})
      super error
      @username = username
    end
  end

  # Raised when a room is not found.
  class RoomNotFoundError < NotFoundError
    # @return [String] the room that was not found.
    attr_reader :room

    # Initializes a new RoomNotFoundError instance.
    # @param room [String] Name of the room that was not found.
    # @param error [Hash] The error response from the server.
    def initialize(room, error = {})
      super error
      @room = room
    end
  end

  # Raised when there is an issue with authentication.
  #
  # This can either be because authentication failed outright or because
  # more information is required by the server to successfully authenticate.
  #
  # If authentication failed then the `data` attribute will be an empty hash.
  #
  # If more information is required the `data` hash will contain information
  # about what additional information is needed to authenticate.
  class AuthenticationError < ApiError
    # @return [Hash] a hash with information about the additional information
    #   required by the server for authentication, if any. If the
    #   authentication request failed, this will be an empty hash or `nil`.
    attr_reader :data

    # Initializes a new AuthenticationError instance.
    # @param error [Hash] The error response from the server.
    def initialize(error = {})
      super

      # Set data to be the error response hash WITHOUT the error code and
      # error values. This will leave it with only the data relevant for
      # handling authentication.
      @data = error.select { |key| !%w(errcode error).include? key }
    end
  end
end
