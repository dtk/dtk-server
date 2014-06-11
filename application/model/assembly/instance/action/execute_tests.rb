module DTK
  class Assembly::Instance
    module Action
      class ExecuteTestsV2 < ActionResultsQueue::Result
        def self.initiate(assembly_instance,nodes,action_results_queue, type, opts={})
          new(assembly_instance,nodes,action_results_queue, type, opts).initiate()
        end
        
        def initialize(assembly_instance,nodes,action_results_queue, type, opts={})
          @assembly_instance = assembly_instance
          @nodes = nodes
          @action_results_queue = action_results_queue 
          @type = type
          @filter = opts[:filter]

        end

        def initiate()
          test_components = get_test_components_with_stub()
=begin
             pp test_components
{:test_instances=>
  [{:module_name=>"mongodb",
    :component=>"node1/mongodb",
    :test_component=>"network_port_check",
    :test_name=>"network_port_check_spec.rb",
    :params=>{:mongo_port=>"27017", :mongo_web_port=>"28017"}}]}
=end          
          

          #Rich: version context should be not for the components but be for the module containing the tests; so need to look at test_components to determine this
          version_context = Array.new
=begin
          version_context = 
            unless cmp_templates.empty?
              ComponentModule::VersionContextInfo.get_in_hash_form_from_templates(cmp_templates)
            else
              Log.error("Unexpected that cmp_instances is empty")
              nil
            end
          pp [:debug_version_context,version_context]
=end          
          #Bakir: Added stub method to retrieve list of all test components and their params based on regular components
          #This hash structure is then passed to the mcollective agent
          
          indexes = nodes.map{|r|r[:id]}
          action_results_queue.set_indexes!(indexes)
          ndx_pbuilderid_to_node_info =  nodes.inject(Hash.new) do |h,n|
            h.merge(n.pbuilderid => {:id => n[:id].to_s, :display_name => n[:display_name]}) 
          end
          callbacks = {
            :on_msg_received => proc do |msg|
              response = CommandAndControl.parse_response__execute_action(nodes,msg)
              if response and response[:pbuilderid] and response[:status] == :ok
                node_info = ndx_pbuilderid_to_node_info[response[:pbuilderid]]
                raw_data = response[:data].map{|r|node_info.merge(r)}
                packaged_data = DTK::ActionResultsQueue::Result.new(node_info[:display_name],raw_data)
                action_results_queue.push(node_info[:id], (type == :node) ? packaged_data.data : packaged_data)
              elsif response[:status] != :ok  
                node_info = ndx_pbuilderid_to_node_info[response[:pbuilderid]]       
                action_results_queue.push(node_info[:id],response[:data])
              end
            end
          }
          
          #part of the code used to decide which components belong to which nodes. 
          #based on that fact, serverspec tests will be triggered on node only for components that actually belong to that specific node
          node_hash = {}
          components_including_node_name = []
          unless test_components.empty?
            nodes.each do |node|
              pp "Components: #{test_components}"
              components_array = []
              test_components[:test_instances].each do |comp|
                if comp[:component].include? "#{node[:display_name]}/"
                  components_array << comp
                  components_including_node_name << comp
                end
              end
              node_hash[node[:id]] = {:components => components_array, :instance_id => node[:external_ref][:instance_id], :version_context => version_context}
            end
          end
          
          #components_including_node_name array will be empty if execute-test agent is triggered from specific node context
          if components_including_node_name.empty?
            components = filter[:components] #TODO: temp
            CommandAndControl.request__execute_action(:execute_tests_v2,:execute_tests_v2,nodes,callbacks, {:components => components, :version_context => version_context})
          else
            CommandAndControl.request__execute_action_per_node(:execute_tests_v2,:execute_tests_v2,node_hash,callbacks)
          end
        end
       private

        attr_reader :assembly_instance, :nodes, :action_results_queue, :type, :filter
        def get_test_components_with_stub()
          if ret = get_test_components()
            return ret
          end

          #stub part
          ret = {
            :test_instances => []
          }
          components = filter[:components]
          (components||[]).each do |component|
            if component.include? "mongo"
              ret[:test_instances] << { 
                :module_name => "mongodb", 
                :component => component, 
                :test_component => "network_port_check",
                :test_name => "network_port_check_spec.rb",
                :params => {:mongo_port => '27017',:mongo_web_port => '28017'}
              }
            end
          end
          ret
        end

        def get_test_components()
          Component::Test.get_linked_tests(assembly_instance)
        end

        #TODO: deprecate
        #TODO: rather than passing in strings, have controller/helper methods convert to ids and objects, rather than passing 
        def get_augmented_component_templates(nodes,components)
          ret = Array.new
          if nodes.empty?
            return ret
          end

          sp_hash = {
            :cols => [:id,:group_id,:instance_component_template_parent,:node_node_id],
            :filter => [:oneof,:node_node_id,nodes.map{|n|n.id()}]
          }
          ret = Model.get_objs(nodes.first.model_handle(:component),sp_hash).map do |r|
            r[:component_template].merge(:node_node_id => r[:node_node_id], :component_instance_id => r[:id])
          end
          if components.nil? or components.empty? or !components.include? "/"
            return ret
          end
          
          cmp_node_names = components.map do |name_pairs|
            if name_pairs.include? "/"
              split = name_pairs.split('/') 
                if split.size == 2
                  {:node_name => split[0],:component_name => Component.display_name_from_user_friendly_name(split[1])}
                else
                  Log.error("unexpected component form: #{name_pairs}; skipping")
                  nil
                end
            else
                {:component_name => Component.display_name_from_user_friendly_name(name_pairs)}
            end
          end.compact
          ndx_node_names = nodes.inject(Hash.new){|h,n|h.merge(n[:id] => n[:display_name])}
          
          #only keep matching ones
          ret.select do |cmp_template|
            cmp_node_names.find do |r|
              r[:node_name] == ndx_node_names[cmp_template[:node_node_id]] and r[:component_name] == cmp_template[:display_name]
            end
          end
        end
        
      end

      class ExecuteTests < ActionResultsQueue::Result
        def self.initiate(nodes,action_results_queue, type, components)
          #TODO: Rich: Put in logic here to get component instnces so can call an existing function used for converge to get all
          cmp_templates = get_component_templates(nodes,components)
          pp [:debug_cmp_templates,cmp_templates]
          version_context = 
            unless cmp_templates.empty?
              ComponentModule::VersionContextInfo.get_in_hash_form_from_templates(cmp_templates)
            else
              Log.error("Unexpected that cmp_instances is empty")
              nil
            end
          pp [:debug_version_context,version_context]
          
          indexes = nodes.map{|r|r[:id]}
          action_results_queue.set_indexes!(indexes)
          ndx_pbuilderid_to_node_info =  nodes.inject(Hash.new) do |h,n|
            h.merge(n.pbuilderid => {:id => n[:id].to_s, :display_name => n[:display_name]}) 
          end
          callbacks = {
            :on_msg_received => proc do |msg|
              response = CommandAndControl.parse_response__execute_action(nodes,msg)
              if response and response[:pbuilderid] and response[:status] == :ok
                node_info = ndx_pbuilderid_to_node_info[response[:pbuilderid]]
                raw_data = response[:data].map{|r|node_info.merge(r)}
                packaged_data = new(node_info[:display_name],raw_data)
                action_results_queue.push(node_info[:id], (type == :node) ? packaged_data.data : packaged_data)
              elsif response[:status] != :ok  
                node_info = ndx_pbuilderid_to_node_info[response[:pbuilderid]]       
                action_results_queue.push(node_info[:id],response[:data])
              end
            end
          }
          
          #part of the code used to decide which components belong to which nodes. 
          #based on that fact, serverspec tests will be triggered on node only for components that actually belong to that specific node
          node_hash = {}
          components_including_node_name = []
          unless components.empty?
            nodes.each do |node|
              puts "Components: #{components}"
              components_array = []
              components.each do |comp|
                if comp.include? "#{node[:display_name]}/"
                  components_array << comp
                  components_including_node_name << comp
                end
              end
              node_hash[node[:id]] = {:components => components_array, :instance_id => node[:external_ref][:instance_id], :version_context => version_context}
            end
          end
          
          #components_including_node_name array will be empty if execute-test agent is triggered from specific node context
          if components_including_node_name.empty?
            CommandAndControl.request__execute_action(:execute_tests,:execute_tests,nodes,callbacks, {:components => components, :version_context => version_context})
          else
            CommandAndControl.request__execute_action_per_node(:execute_tests,:execute_tests,node_hash,callbacks)
          end
        end
        private
        #TODO: some of this logic can be leveraged by code below node_hash
        #TODO: even more idea, but we can iterate to it have teh controller/helper methods convert to ids and objects, ratehr than passing 
        #strings in components
        def self.get_component_templates(nodes,components)
          ret = Array.new
          if nodes.empty?
            return ret
          end
          sp_hash = {
            :cols => [:id,:group_id,:instance_component_template_parent,:node_node_id],
            :filter => [:oneof,:node_node_id,nodes.map{|n|n.id()}]
          }
          ret = Model.get_objs(nodes.first.model_handle(:component),sp_hash).map do |r|
            r[:component_template].merge(:node_node_id => r[:node_node_id])
          end
            if components.nil? or components.empty? or !components.include? "/"
              return ret
            end
          
          cmp_node_names = components.map do |name_pairs|
            if name_pairs.include? "/"
              split = name_pairs.split('/') 
              if split.size == 2
                {:node_name => split[0],:component_name => Component.display_name_from_user_friendly_name(split[1])}
              else
                  Log.error("unexpected component form: #{name_pairs}; skipping")
                nil
              end
            else
              {:component_name => Component.display_name_from_user_friendly_name(name_pairs)}
            end
          end.compact
          ndx_node_names = nodes.inject(Hash.new){|h,n|h.merge(n[:id] => n[:display_name])}
          
          #only keep matching ones
          ret.select do |cmp_template|
            cmp_node_names.find do |r|
                r[:node_name] == ndx_node_names[cmp_template[:node_node_id]] and r[:component_name] == cmp_template[:display_name]
            end
          end
        end
      end
    end
  end   
end

