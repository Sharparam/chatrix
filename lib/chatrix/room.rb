require 'chatrix/event_processor'

require 'logger'
require 'wisper'

module Chatrix
  class Room < EventProcessor
    include Wisper::Publisher

    attr_reader :id, :alias, :name, :topic

    # Debugging
    @@log = Logger.new $stdout

    def initialize(id, users, matrix)
      super()

      @id = id
      @aliases = []
      @users = users
      @matrix = matrix
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

      case event['type']
      when 'm.room.member'
        @users.process_member_event self, event
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
      else
        @@log.debug(:state) { "Unhandled event: #{event}" }
      end

      processed event
    end

    def process_timeline_event(event)
      return if processed? event

      case event['type']
      when 'm.room.message'
        process_message_event event
      when 'm.room.member'
        @users.process_member_event self, event
      else
        @@log.debug(:timeline) { "Unhandled event: #{event}" }
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
