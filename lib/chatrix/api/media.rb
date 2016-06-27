module Chatrix
  module Api
    # Contains methods for accessing the media endpoints of a server.
    class Media < ApiComponent
      # API path for media operations.
      #
      # Because for some reason this one is different.
      MEDIA_PATH = '/_matrix/media/r0'.freeze

      # Initializes a new Media instance.
      # @param matrix [Matrix] The matrix API instance.
      def initialize(matrix)
        super
        @media_uri = @matrix.homeserver + MEDIA_PATH
      end

      # Download media from the server.
      # @param server [String] The server component of an `mxc://` URL.
      # @param id [String] The media ID of the `mxc://` URL (the path).
      # @return [HTTParty::Response] The HTTParty response object for the request.
      #   Use the response object to inspect the returned data.
      def download(server, id)
        make_request(
          :get,
          "/download/#{server}/#{id}",
          headers: { 'Accept' => '*/*' },
          base: @media_uri
        )
      end

      # Download the thumbnail for a media resource.
      # @param server [String] The server component of an `mxc://` URL.
      # @param id [String] The media ID of the `mxc://` URL (the path).
      # @param width [Fixnum] Desired width of the thumbnail.
      # @param height [Fixnum] Desired height of the thumbnail.
      # @param method ['scale', 'crop'] Desired resizing method.
      # @return [HTTParty::Response] The HTTParty response object for the request.
      #   Use the response object to inspect the returned data.
      def get_thumbnail(server, id, width, height, method = 'scale')
        make_request(
          :get,
          "/thumbnail/#{server}/#{id}",
          headers: { 'Accept' => 'image/jpeg, image/png' },
          params: { width: width, height: height, method: method },
          base: @media_uri
        )
      end

      # Uploads a new media file to the server.
      # @param type [String] The `Content-Type` of the media being uploaded.
      # @param path [String] Path to a file to upload.
      # @return [String] The MXC URL for the uploaded object (`mxc://...`).
      def upload(type, path)
        File.open(path, 'r') do |file|
          make_request(
            :post, '/upload',
            headers: {
              'Content-Type' => type, 'Content-Length' => file.size.to_s,
              'Transfer-Encoding' => 'chunked'
            },
            content: file, base: @media_uri
          )['content_uri']
        end
      end
    end
  end
end
