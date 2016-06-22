module Ratrix
    class RatrixError < StandardError
    end

    class ApiError < RatrixError
    end

    class RequestError < ApiError
        attr_reader :code, :api_message

        def initialize(error)
            @code = error['errcode']
            @api_message = error['error']
        end
    end

    class ForbiddenError < ApiError
    end

    class NotFoundError < ApiError
    end

    class UserNotFoundError < NotFoundError
        attr_reader :username

        def initialize(username)
            @username = username
        end
    end

    class AvatarNotFoundError < NotFoundError
        attr_reader :username

        def initialize(username)
            @username = username
        end
    end

    class RoomNotFoundError < NotFoundError
        attr_reader :room

        def initialize(room)
            @room = room
        end
    end
end
