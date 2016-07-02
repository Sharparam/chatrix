# encoding: utf-8
# frozen_string_literal: true

module Chatrix
  module Api
    # Wraps a matrix instance for use in calling API endpoints.
    class ApiComponent
      # Initializes a new ApiComponent instance.
      # @param matrix [Matrix] The matrix API instance.
      def initialize(matrix)
        @matrix = matrix
      end

      protected

      # Makes an API request using the underlying Matrix instance.
      # @param args Parameters to pass to Matrix#make_request.
      # @yield (see Matrix#make_request)
      # @return (see Matrix#make_request)
      def make_request(*args, &block)
        @matrix.make_request(*args, &block)
      end
    end
  end
end
