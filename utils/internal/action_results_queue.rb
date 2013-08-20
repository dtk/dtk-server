module DTK
  #cross threads may eb seperate requests for new action results queue, but no locking on allocated instance
  class ActionResultsQueue

    #returns :is_complete => is_complete, :results => results
    # since action result queue post processing is specific to netstats results, 
    # you can disable mentioned post processing via flag :disable_post_processing
    def self.get_results(queue_id,ret_only_if_complete,disable_post_processing, sort_key = :port)
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
      ret = {:is_complete => is_complete, :results => (disable_post_processing ? results : Result.post_process(results, sort_key))}
      return ret
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
      def self.post_process(results, sort_key = :port)
        unless results.kind_of?(Hash) #and results.values.first.kind_of?(self)
          return results
        end
        ret = Array.new
        #sort by node name and prune out keys with no results
        pruned_sorted_keys = results.reject{|k,v|v.nil?}.sort{|a,b|a[1].node_name <=> b[1].node_name}.map{|r|r.first}
        pruned_sorted_keys.each do |node_id|
          result = results[node_id]
          node_name = result.node_name
          first = true
          result.data.sort{|a,b|a[sort_key] <=> b[sort_key]}.each do |r|
            if first
              ret << r.merge(:node_id => node_id,:node_name => node_name)
              first = false
            else
              ret << r
            end
          end
        end
        ret
      end
    end
  end
end
