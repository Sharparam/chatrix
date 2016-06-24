require 'chatrix/event_processor'
require 'chatrix/permissions'

require 'logger'
require 'set'
require 'wisper'

module Chatrix
  # Provides functionality for interacting with a room.
  class Room < EventProcessor
    include Wisper::Publisher

    attr_reader :id, :alias, :name, :topic, :creator, :guest_access,
                :history_visibility, :join_rule

    def initialize(id, users, matrix)
      super()

      @id = id
      @aliases = []
      @users = users
      @matrix = matrix
      @members = Set.new

      @permissions = Permissions.new self
    end

    def send_message(message)
      @matrix.send_message @id, message
    end

    def send_notice(message)
      @matrix.send_notice @id, message
    end

    def send_emote(message)
      @matrix.send_emote @id, message
    end

    def can?(user, action)
      @permissions.can? user, action
    end

    def can_set?(user, event)
      @permissions.can_set? user, event
    end

    def process_join(data)
      process_state data['state'] if data.key? 'state'
      process_timeline data['timeline'] if data.key? 'timeline'
    end

    def process_invite(data)
    end

    def process_leave(data)
    end

    def to_s
      return @name if @name
      return @alias if @alias
      @id
    end

    private

    def process_state(data)
      return unless data.key? 'events'
      data['events'].each { |e| process_state_event e }
    end

    def process_timeline(data)
      return unless data.key? 'events'
      data['events'].each { |e| process_timeline_event e }
    end

    def process_state_event(event)
      return if processed? event

      broadcast(:state, self, event)

      case event['type']
      when 'm.room.create'
        @creator = event['content']['creator']
        broadcast(:creator, self, @creator)
      when 'm.room.member'
        process_member_event event
      when 'm.room.canonical_alias'
        @alias = event['content']['alias']
        broadcast(:alias, self, @alias)
      when 'm.room.aliases'
        @aliases.replace event['content']['aliases']
        broadcast(:aliases, self, @aliases.dup)
      when 'm.room.name'
        @name = event['content']['name']
        broadcast(:name, self, @name)
      when 'm.room.topic'
        @topic = event['content']['topic']
        broadcast(:topic, self, @topic)
      when 'm.room.power_levels'
        process_power_levels_event event
      when 'm.room.guest_access'
        @guest_access = event['content']['guest_access'] == 'can_join'
        broadcast(:guest_access, self, @guest_access)
      when 'm.room.history_visibility'
        @history_visibility = event['content']['history_visibility']
        broadcast(:history_visibility, self, @history_visibility)
      when 'm.room.join_rules'
        @join_rule = event['content']['join_rule']
        broadcast(:join_rule, self, @join_rule)
      end

      processed event
    end

    def process_member_event(event)
      @users.process_member_event self, event
      user = @users[event['sender']]
      membership = event['membership'].to_sym

      if membership == :join
        @members.add user
      else
        @members.delete user
      end

      broadcast(membership, self, user)
    end

    def process_power_levels_event(event)
      content = event['content']
      @permissions.update content
      broadcast(:permissions, self)
      @users.process_power_levels self, content['users']
    end

    def process_timeline_event(event)
      return if processed? event

      broadcast(:timeline, self, event)

      case event['type']
      when 'm.room.message'
        process_message_event event
      when 'm.room.member'
        @users.process_member_event self, event
      end

      processed event
    end

    def process_message_event(event)
      type = event['content']['msgtype']
      body = event['content']['body']
      sender = @users[event['sender']]

      case type
      when 'm.emote'
        broadcast(:emote, self, sender, body)
      when 'm.notice'
        broadcast(:notice, self, sender, body)
      else
        if event['content'].key? 'format'
          case event['content']['format']
          when 'org.matrix.custom.html'
            broadcast(:html, self, sender,
                      event['content']['formatted_body'], body)
          else
            broadcast(:message, self, sender, body)
          end
        else
          broadcast(:message, self, sender, body)
        end
      end
    end
  end
end
