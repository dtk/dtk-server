require 'iconv'
# important, due to issue with class loading make sure this class is loaded first
r8_nested_require('command_and_control', 'adapters/node_config/mcollective')

module DTK
  # cross threads may be seperate requests for new action results queue, but no locking on allocated instance
  class ActionResultsQueue
    r8_require('workflow/adapters/ruote/participant/mcollective_debug')
    include McollectiveDebug

    Lock = Mutex.new
    Queues = {}
    @@count = 0
    def initialize(_opts = {})
      Lock.synchronize do
        @indexes = []
        @@count += 1
        @id = @@count
        @results = {}
        Queues[@id] = self
      end
    end

    ##
    # Initiates commmand on nodes
    def initiate(nodes, params, _opts = {})
      indexes = nodes.map { |r| r[:id] }
      set_indexes!(indexes)
      ndx_pbuilderid_to_node_info =  nodes.inject({}) do |h, n|
        h.merge(n.pbuilderid => { id: n[:id], display_name: n.assembly_node_print_form() })
      end

      callbacks = {
        on_msg_received: proc do |msg|
          inspect_agent_response(msg)
          response = CommandAndControl.parse_response__execute_action(nodes, msg, params)

          node_info = ndx_pbuilderid_to_node_info[response[:pbuilderid]]
          data = response[:data]
          data = process_data!(data, node_info)
          push(node_info[:id], data)
        end
      }
      action_hash = action_hash()

      fail Error.new('Unexpected that :agent is not in action_hash')   unless action_hash[:agent]
      fail Error.new('Unexpected that :method is not in action_hash') unless  action_hash[:method]

      params.merge!(protocol: messaging_protocol())


      # this will load adapter and proceed to send requests towards mcollective / stomp / ...
      CommandAndControl.request__execute_action(action_hash[:agent], action_hash[:method], nodes, callbacks, params)
    end

    # can be overwritten
    def messaging_protocol
      # default: mcollective
      R8::Config[:command_and_control][:node_config][:type]
    end

    # can be overwritten
    def process_data!(data, _node_info)
      Result.normalize_data_to_utf8_output!(data)
    end

    private :process_data!

    # returns :is_complete => is_complete, :results => results
    # since action result queue post processing is specific to netstats results,
    # you can disable mentioned post processing via flag :disable_post_processing
    def self.get_results(queue_id, ret_only_if_complete, disable_post_processing, sort_key = :port)
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
        results.each do |_k, v|
          disable_post_processing = true if v.is_a?(Hash)
        end
      end
      {
        is_complete: is_complete,
        results: (disable_post_processing ? results : Result.post_process(results, sort_key))
      }
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

    def push(index, el)
      @results[index] = el
    end

    def all_if_complete
      # TODO: error message if @results.size > @indexes.size
      (@results.size >= @indexes.size) ? @results : nil
    end

    def ret_whatever_is_complete
      @indexes.inject({}) { |h, i| h.merge(i => @results[i]) }
    end

    class Result
      def initialize(node_name, data)
        @data = data
        @node_name = node_name
      end

      attr_reader :data, :node_name

      def self.post_process(results, sort_key = :port)
        unless results.is_a?(Hash) #and results.values.first.kind_of?(self)
          return results
        end

        ret = []
        # sort by node name and prune out keys with no results
        pruned_sorted_keys = results.reject { |_k, v| v.nil? }.sort { |a, b| a[1].node_name <=> b[1].node_name }.map(&:first)
        pruned_sorted_keys.each do |node_id|
          result = results[node_id]
          node_name = result.node_name
          first = true

          result.data.sort { |a, b| a[sort_key] <=> b[sort_key] }.each do |r|
            if first
              ret << r.merge(node_id: node_id, node_name: node_name)
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
        if data && data.is_a?(Hash)
          ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
          output = data[:output] || ''

          # check if string
          return data unless output.is_a?(String)

          valid_output = ic.iconv(output + ' ')[0..-2]
          data[:output] = ic.iconv(output + ' ')[0..-2]
        end

        data
      end
    end
  end
end
