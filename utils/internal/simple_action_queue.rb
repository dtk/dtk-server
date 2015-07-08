
module DTK
  # One dimensional queue to support much simpler needs for queing simpler results.
  # Unlike ActionResultQueue there is no need to support multiple results from different
  # nodes.
  class QueueNotFound < Error
    def initialize(queue_id, available_ids)
      super("Simple Action queue could not find queue with ID #{queue_id}, available queues [#{available_ids.join(',')}]")
    end

  end

  class SimpleActionQueue
    def self.get_results(queue_id)
      queue, response_results = self[queue_id], nil

      raise QueueNotFound.new(queue_id, self.available_ids) if queue.nil?

      unless queue.result.nil?
        response_results = queue.result
        delete(queue_id)
      end

      return { result: response_results }
    end

    attr_accessor :id, :result

    Lock = Mutex.new
    Queues = {}
    @@count = 0

    def initialize
      Lock.synchronize do
        @@count += 1
        @id = @@count
        @result = nil
        Queues[@id] = self
      end
    end

    def self.delete(queue_id)
      Lock.synchronize do
        Queues.delete(queue_id.to_i)
      end
    end

    def self.[](queue_id)
      Queues[queue_id.to_i]
    end

    def self.available_ids
      Queues.keys
    end

    def set_result(el)
      # TODO: Rich: thik this is an error @result = el.data
      @result = el
    end
  end
end

