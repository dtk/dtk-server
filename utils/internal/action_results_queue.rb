require 'iconv'

module DTK
  # cross threads may eb seperate requests for new action results queue, but no locking on allocated instance
  class ActionResultsQueue
    ##
    # Initiates commmand on nodes 
    def initiate(nodes,params,opts={})
      indexes = nodes.map{|r|r[:id]}
      set_indexes!(indexes)
      ndx_pbuilderid_to_node_info =  nodes.inject(Hash.new) do |h,n|
        h.merge(n.pbuilderid => {:id => n[:id], :display_name => n[:display_name]}) 
      end
        
      callbacks = { 
        :on_msg_received => proc do |msg|
          response = CommandAndControl.parse_response__execute_action(nodes,msg)
          if response and response[:pbuilderid] and response[:status] == :ok
            node_info = ndx_pbuilderid_to_node_info[response[:pbuilderid]]
            data = response[:data]
            data = process_data!(data,node_info)
            push(node_info[:id],data)
          end
        end
      }
      action_hash = action_hash()
      unless agent = action_hash[:agent]
        raise Error.new("Unexpected that :agent is not in action_hash")
      end
      unless method = action_hash[:method]
        raise Error.new("Unexpected that :method is not in action_hash")
      end
      CommandAndControl.request__execute_action(agent,method,nodes,callbacks,params)
    end

    # can be overwritten
    def process_data!(data,node_info)
      Result.normalize_data_to_utf8_output!(data)
    end      
    private :process_data!

    # returns :is_complete => is_complete, :results => results
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

      unless results.nil?
        results.each do |k,v|
          disable_post_processing = true if v.is_a?(Hash)
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
      # TODO: error message if @results.size > @indexes.size
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
        # sort by node name and prune out keys with no results
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

      #
      # Takes possible invalid UTF-8 output and ignores invalid bytes
      #
      # http://po-ru.com/diary/fixing-invalid-utf-8-in-ruby-revisited/
      def self.normalize_data_to_utf8_output!(data)

        if data
          ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
          output = data[:output]||''
          valid_output = ic.iconv(output + ' ')[0..-2]
          data[:output] = ic.iconv(output + ' ')[0..-2]
        else
          Log.warn "Skipping UTF-8 normalization since provided output does not have :data element."
        end
        data
      end
    end
  end
end
