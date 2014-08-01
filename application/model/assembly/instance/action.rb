module DTK
  class Assembly::Instance
    module Action
      r8_nested_require('action','execute_tests')
      r8_nested_require('action','ssh_access')
      class GetLog < ActionResultsQueue
       private
        def action_hash()
          {:agent => :tail, :method => :get_log}
        end
      end
      class Grep < ActionResultsQueue
       private
        def action_hash()
          {:agent => :tail, :method => :grep}
        end
      end

      class GetPs < ActionResultsQueue
       private
        def action_hash()
          {:agent => :ps, :method => :get_ps}
        end

        def process_data!(data,node_info)
          Result.new(node_info[:display_name],data.map{|r|node_info.merge(r)})
        end
      end

      class GetNetstats < ActionResultsQueue
       private
        def action_hash()
          {:agent => :netstat, :method => :get_tcp_udp}
        end

        def process_data!(data,node_info)
          ndx_ret = Hash.new
          data.each do |r|
            next unless r[:state] == "LISTEN" || r[:protocol] == "udp"
            if r[:local] =~ /(^.+):([0-9]+$)/
              address = $1
              port = $2.to_i
              next unless address =~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$|::/
              ndx_ret["#{address}_#{port}"] ||= {
                :port => port,
                :local_address => address,
                :protocol => r[:protocol]
              }
              end
          end
          Result.new(node_info[:display_name],ndx_ret.values)
        end
      end
    end

#TODO: cleanup everything below this
    module ActionMixin
      def initiate_execute_tests(action_results_queue, node_id=nil, components=nil)
        nodes =  action_get_leaf_nodes()
        nodes = nodes.select { |node| node[:id] == node_id.to_i } unless (node_id.nil? || node_id.empty?)
        
        # Special case filtering of nodes that are not running and executing agent only on those that are running
        component_nodes = Array.new
        
        unless components.empty? || components.nil?
          components.each do |cmp|
            if cmp.include? "/"
              component_nodes << cmp.split("/").first
            end
          end
        end
        nodes = nodes.select { |node| component_nodes.include? node[:display_name] } if (node_id.nil? || node_id.empty?)
        Assembly::Instance::Action::ExecuteTests.initiate(nodes,action_results_queue, :assembly, components)
      end

      def initiate_execute_tests_v2(project,action_results_queue, node_id=nil, components=nil)
        
        nodes =  action_get_leaf_nodes()
        nodes = nodes.select { |node| node[:id] == node_id.to_i } unless (node_id.nil? || node_id.empty?)
        opts = {} 

        # Special case filtering of nodes that are not running and executing agent only on those that are running
        component_nodes = Array.new
        unless components.empty? || components.nil?
          components.each do |cmp|
            if cmp.include? "/"
              component_nodes << cmp.split("/").first
            end
          end
          opts.merge!(:filter => {:components => components})
        end
        Assembly::Instance::Action::ExecuteTestsV2.initiate(project,self,nodes,action_results_queue, :assembly, opts)
      end

      def action_get_leaf_nodes()
        get_leaf_nodes(:cols => [:id,:display_name,:external_ref])
      end
    end
  end
end
