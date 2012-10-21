module DTK
  #cross threads may eb seperate requests for new action results queue, but no locking on allocated instance
  class ActionResultsQueue

    #returns :is_complete => is_complete, :results => results
    def self.get_results(queue_id,ret_only_if_complete)
      is_complete = results = nil
      unless ret_only_if_complete
        results = self[queue_id].ret_whatever_is_complete
        delete(queue_id)
        is_complete = true
      else
        results = self[queue_id].all_if_complete()
        if results
          delete(queue_id)
          is_complete = true
        else
          is_complete = false
        end
      end
      {:is_complete => is_complete, :results => Result.post_process(results)}
    end

    Lock = Mutex.new
    Queues = Hash.new
    @@count = 0
    def initialize(indexes=[])
      Lock.synchronize do
        @indexes = indexes
        @@count += 1
        @id = @@count
        @results = Hash.new
        Queues[@id] = self
      end
    end

    def set_indexes!(indexes)
      @indexes = indexes
    end

    attr_reader :id

    def self.delete(queue_id)
      Lock.synchronize do
        Queues.delete(queue_id.to_i)
      end
    end

    def self.[](queue_id)
      Queues[queue_id.to_i]
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

    class Result
      def initialize(node_name,data)
        @data = data
        @node_name = node_name
      end
      attr_reader :data, :node_name
      def self.post_process(results)
        unless results.kind_of?(Hash) #and results.values.first.kind_of?(self)
          return results
        end
        ret = Array.new
        results.each do |node_id,result|
          node_name = result.node_name
          result.data.each do |r|
            ret << r.merge(:node_id => node_id,:node_name => node_name)
          end
        end
        ret
      end
    end
  end
end
