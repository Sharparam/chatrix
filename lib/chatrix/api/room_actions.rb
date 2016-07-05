# encoding: utf-8
# frozen_string_literal: true

module Chatrix
  module Api
    # Contains methods for performing actions on rooms.
    class RoomActions < ApiComponent
      # Initializes a new RoomActions instance.
      # @param matrix [Matrix] The matrix API instance.
      def initialize(matrix)
        super
        @transaction_id = 0
      end

      # Creates a new room on the server.
      #
      # @param data [Hash] Additional data to send when creating the room.
      #   None of these are required when creating a new room.
      #
      # @option data [Array<String>] :invite A list of user IDs to invite
      #   when the room has been created.
      # @option data [String] :name A custom name to give the room.
      # @option data ['public', 'private'] :visibility The visibility to
      #   create the room with.
      # @option data [Array<Hash>] :invite_3pid A list of third-party
      #   ID objects to invite to the room.
      # @option data [String] :topic A topic to set for the room.
      # @option data ['public_chat', 'trusted_private_chat', 'private_chat']
      #   :preset Sets various state events based on a preset.
      #
      #    * **`private_chat`**: `join_rules` is `invite`,
      #      `history_visibility` is `shared`.
      #    * **`trusted_private_chat`**: `join_rules` is `invite`,
      #      `history_visibility` is `shared`, all invited users get the
      #      same power level as the room creator.
      #    * **`public_chat`**: `join_rules` is `public`,
      #      `history_visibility` is `shared`.
      # @option data [Hash{String => Object}] :creation_content Additional data
      #   to add to the `'m.room.create'` content.
      # @option data [Array<Hash>] :initial_state A list of state events to
      #   set in the room.
      # @option data [String] :room_alias_name The **localpart** of the alias
      #   to sets for this room. The localpart is the part of the alias
      #   between the "`#`" sign and the "`:host.tld`" ending part. In the
      #   alias `#hello:world.org`, the "`hello`" part is the localpart.
      #
      # @return [String] the ID of the created room.
      #
      # @example Create a room with an alias, name, and invited user
      #   id = create(
      #     room_alias_name: 'foobar',
      #     name: 'Foo Bar Baz!',
      #     invite: ['@silly:example.org']
      #   )
      #
      #   puts "Room #{id} created!"
      def create(data = {})
        make_request(:post, '/createRoom', content: data)['room_id']
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

      # @overload invite(room, user)
      #   Invites a user to a room by ID.
      #   @param room [String] The room to invite the user to.
      #   @param user [String] The user ID to send the invite to.
      #   @return [Boolean] `true` if the user was successfully invited,
      #     otherwise `false`.
      # @overload invite(room, data)
      #   Invites a user to a room by their 3PID information.
      #   @param room [String] The room to invite the user to.
      #   @param data [Hash] 3PID info for the user.
      #   @return [Boolean] `true` if the user was successfully invited,
      #     otherwise `false`.
      def invite(room, data)
        data = { user_id: data } if data.is_a? String
        make_request(:post, "/rooms/#{room}/invite", content: data).code == 200
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
      # @param clean [String, nil] If set, this will be put in the `body`
      #   field of the content, to be used as the message when the formatted
      #   version cannot be displayed.
      #
      # @return (see #send_message_raw)
      #
      # @example Sending an HTML message
      #   send_html('#html:matrix.org',
      #             '<strong>Hello</strong> <em>world</em>!')
      def send_html(room, html, clean = nil)
        send_message_raw(
          room,
          msgtype: 'm.text',
          format: 'org.matrix.custom.html',
          body: clean || html.gsub(%r{</?[^>]*?>}, ''), # TODO: Make this better
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

      # Updates the marker for the given receipt type to point to the
      # specified event.
      #
      # @param room [String] The room to update the receipt in.
      # @param event [String] The new event to point the receipt to.
      # @param type [String] The receipt type to update.
      # @param data [Hash] Any additional data to attach to `content`.
      # @return [Boolean] `true` if the receipt was successfully updated,
      #   otherwise `false`.
      def set_receipt(room, event, type = 'm.read', data = {})
        make_request(
          :post,
          "/rooms/#{room}/receipt/#{type}/#{event}",
          content: data
        ).code == 200
      end

      # Redacts a room event from the server.
      #
      # @param room [String] The room to redact the event from.
      # @param event [String] The event to redact.
      # @param reason [String] The reason for redacting the event.
      # @return [String] The ID for the redaction event.
      def redact(room, event, reason)
        make_request(
          :put,
          "/rooms/#{room}/redact/#{event}/#{@transaction_id += 1}",
          content: { reason: reason }
        )['event_id']
      end
    end
  end
end
