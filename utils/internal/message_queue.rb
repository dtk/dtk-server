require 'celluloid'
require 'redis'

module DTK
  class MessageQueue
    include Singleton

    attr_accessor :queue_internal

    def initialize
      @queue_internal = QueueInternal.new
    end

    def self.store(type, message)
      self.instance.queue_internal.async.store(message, CurrentSession.get_username(), type)
    end

    def self.retrive()
      self.instance.queue_internal.retrive(CurrentSession.get_username())
    end

  end


  class QueueInternal
    include Celluloid

    # sets queue time to live - each time msg enter queue TTL is refreshed
    QUEUE_TTL = 60

    attr_accessor :queue_data

    def initialize
      @redis_queue = Redis.new
    end

    def store(message, session_username, type = :info)
      @redis_queue.lpush  session_username, { :message => message, :type => type }.to_json
      @redis_queue.expire session_username, QUEUE_TTL
    end

    def retrive(session_username)
      messages = []
      msg      = @redis_queue.rpop(session_username)
      messages << JSON.parse(msg) if msg
      messages
    end
  end
end
