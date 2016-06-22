module Ratrix
  # Generic faults from the library.
  class RatrixError < StandardError
  end

  # Errors that stem from an API call.
  class ApiError < RatrixError
  end

  # Error raised when a request is badly formatted.
  class RequestError < ApiError
    attr_reader :code, :api_message

    def initialize(error)
      @code = error['errcode']
      @api_message = error['error']
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
    attr_reader :username

    def initialize(username)
      @username = username
    end
  end

  # Raised when a user's avatar is not found.
  class AvatarNotFoundError < NotFoundError
    attr_reader :username

    def initialize(username)
      @username = username
    end
  end

  # Raised when a room is not found.
  class RoomNotFoundError < NotFoundError
    attr_reader :room

    def initialize(room)
      @room = room
    end
  end
end
