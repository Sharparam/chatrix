module Chatrix
  module Api
    # Wraps a matrix instance for use in calling API endpoints.
    class ApiComponent
      # Initializes a new ApiComponent instance.
      def initialize(matrix)
        @matrix = matrix
      end

      protected

      # Makes an API request using the underlying Matrix instance.
      # @param args Parameters to pass to Matrix#make_request.
      # @yield [fragment] HTTParty will call the block during the request.
      def make_request(*args, &block)
        @matrix.make_request(*args, &block)
      end
    end
  end
end
