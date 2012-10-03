module DTK
  #cross threads may eb seperate requests for new action results queue, but no locking on allocated instance
  class ActionResultsQueue
    Lock = Mutex.new
    Queues = Hash.new
    @@count = 0
    def initiliaze(indexes)
      Lock.synchronize do
        @indexes = indexes
        @@count += 1
        @id = @@count
        @results = Hash.new
        Queues[@id] = self
      end
    end
    attr_reader :id
    def self.delete(queue_id)
      Lock.synchronize do
        Queues.delete(queue_id)
      end
    end

    def push(index,el)
      #TODO: error message if unexpected index
      @results[index] = el
    end
    def all_if_complete()
      #TODO: error message if @results.size > @indexes.size
      (@results.size >= @indexes.size) ? @results : nil
    end
    
    def ret_whatever_is_complete()
      @indexes.inject(Hash.new){|h,i| h.merge(i => @results[i])} 
    end
  end
end
