module Chatrix
  # Describes a message sent in a room.
  class Message
    # Supported message types.
    #
    # `:html` is a special message type parsed in {#parse_body!}.
    TYPES = {
      'm.text' => :text,
      'm.emote' => :emote,
      'm.notice' => :notice
    }.freeze

    # @return [Hash] The raw message data (the `content` field).
    attr_reader :raw

    # @return [Symbol,nil] The type of message. Will be nil if the type
    #   failed to parse.
    attr_reader :type

    # @return [User] The user who sent this message.
    attr_reader :sender

    # @return [String] The text content of the message. If the message is
    #   of `:html` type, this will contain HTML format. To get the raw
    #   message text, use the `'body'` field of the {#raw} hash.
    attr_reader :body

    # Initializes a new Message instance.
    #
    # @param sender [User] The user who sent the message.
    # @param content [Hash] The message content.
    def initialize(sender, content)
      @raw = content

      @type = TYPES[@raw['msgtype']]
      @body = @raw['body']
      @sender = sender

      parse_body!
    end

    private

    # Parses the message content to see if there's any special formatting
    # available.
    def parse_body!
      return unless @raw.key? 'format'
      case @raw['format']
      when 'org.matrix.custom.html'
        @type = :html
        @formatted = @raw['formatted_body']
      end
    end
  end
end
