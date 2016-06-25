module Chatrix
  module Api
    # Contains methods for performing actions on rooms.
    class RoomActions < ApiComponent
      # Initializes a new RoomActions instance.
      # @param matrix [Matrix] The matrix API instance.
      def initialize(matrix)
        super
      end

      # Joins a room on the homeserver.
      #
      # @param room [String] The room to join.
      # @param third_party_signed [Hash,nil] If provided, the homeserver must
      #   verify that it matches a pending `m.room.third_party_invite` event in
      #   the room, and perform key validity checking if required by the event.
      # @return [String] The ID of the room that was joined is returned.
      def join(room, third_party_signed = nil)
        if third_party_signed
          make_request(
            :post,
            "/join/#{room}",
            content: { third_party_signed: third_party_signed }
          )['room_id']
        else
          make_request(:post, "/join/#{room}")['room_id']
        end
      end

      # Leaves a room (but does not forget about it).
      #
      # @param room [String] The room to leave.
      # @return [Boolean] `true` if the room was left successfully,
      #   otherwise `false`.
      def leave(room)
        make_request(:post, "/rooms/#{room}/leave").code == 200
      end

      # Forgets about a room.
      #
      # @param room [String] The room to forget about.
      # @return [Boolean] `true` if the room was forgotten successfully,
      #   otherwise `false`.
      def forget(room)
        make_request(:post, "/rooms/#{room}/forget").code == 200
      end

      # Kicks a user from a room.
      #
      # This does not ban the user, they can rejoin unless the room is
      # invite-only, in which case they need a new invite to join back.
      #
      # @param room [String] The room to kick the user from.
      # @param user [String] The user to kick.
      # @param reason [String] The reason for the kick.
      # @return [Boolean] `true` if the user was successfully kicked,
      #   otherwise `false`.
      #
      # @example Kicking an annoying user
      #   kick('#fun:matrix.org', '@anon:4chan.org', 'Bad cropping')
      def kick(room, user, reason)
        make_request(
          :post,
          "/rooms/#{room}/kick",
          content: { reason: reason, user_id: user }
        ).code == 200
      end

      # Kicks and bans a user from a room.
      #
      # @param room [String] The room to ban the user from.
      # @param user [String] The user to ban.
      # @param reason [String] Reason why the ban was made.
      # @return [Boolean] `true` if the ban was carried out successfully,
      #   otherwise `false`.
      #
      # @example Banning a spammer
      #   ban('#haven:matrix.org', '@spammer:spam.com', 'Spamming the room')
      def ban(room, user, reason)
        make_request(
          :post,
          "/rooms/#{room}/ban",
          content: { reason: reason, user_id: user }
        ).code == 200
      end

      # Unbans a user from a room.
      #
      # @param room [String] The room to unban the user from.
      # @param user [String] The user to unban.
      # @return [Boolean] `true` if the user was successfully unbanned,
      #   otherwise `false`.
      def unban(room, user)
        make_request(:post, "/rooms/#{room}/unban", content: { user_id: user })
          .code == 200
      end

      # Sends a message object to a room.
      #
      # @param room [String] The room to send to.
      # @param content [Hash] The message content to send.
      # @param type [String] The type of message to send.
      # @return [String] The event ID of the sent message is returned.
      # @see #send_message_type
      # @see #send_message
      # @see #send_emote
      # @see #send_notice
      # @see #send_html
      def send_message_raw(room, content, type = 'm.room.message')
        make_request(
          :put,
          "/rooms/#{room}/send/#{type}/#{@transaction_id += 1}",
          content: content
        )['event_id']
      end

      # A helper method to send a simple message construct.
      #
      # @param room [String] The room to send the message to.
      # @param content [String] The message to send.
      # @param type [String] The type of message this is.
      #   For example: `'m.text'`, `'m.notice'`, `'m.emote'`.
      # @return (see #send_message_raw)
      def send_message(room, content, type = 'm.text')
        send_message_raw room, msgtype: type, body: content
      end

      # Sends a message formatted using HTML markup.
      #
      # The `body` field in the content will have the HTML stripped out, and is
      # usually presented in clients that don't support the formatting.
      #
      # The `formatted_body` field in the content will contain the actual HTML
      # formatted message (as passed to the `html` parameter).
      #
      # @param room [String] The room to send to.
      # @param html [String] The HTML formatted text to send.
      # @return (see #send_message_raw)
      #
      # @example Sending an HTML message
      #   send_html('#html:matrix.org',
      #             '<strong>Hello</strong> <em>world</em>!')
      def send_html(room, html)
        send_message_raw(
          room,
          msgtype: 'm.text',
          format: 'org.matrix.custom.html',
          body: html.gsub(%r{</?[^>]*?>}, ''), # TODO: Make this better
          formatted_body: html
        )
      end

      # Sends a message to the server informing it about a user having started
      # or stopped typing.
      #
      # @param room [String] The affected room.
      # @param user [String] The user that started or stopped typing.
      # @param typing [Boolean] Whether the user is typing.
      # @param duration [Fixnum] How long the user will be typing for
      #   (in milliseconds).
      # @return [Boolean] `true` if the message sent successfully, otherwise
      #   `false`.
      def send_typing(room, user, typing = true, duration = 30_000)
        make_request(
          :put,
          "/rooms/#{room}/typing/#{user}",
          content: { typingState: { typing: typing, timeout: duration } }
        ).code == 200
      end
    end
  end
end
