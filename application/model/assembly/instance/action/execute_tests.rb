# -*- coding: utf-8 -*-
module DTK
  class Assembly::Instance
    module Action
      class ExecuteTestsV2 < ActionResultsQueue::Result
        def self.initiate(project,assembly_instance,nodes,action_results_queue, type, opts={})
          new(project,assembly_instance,nodes,action_results_queue, type, opts).initiate()
        end
        
        def initialize(project,assembly_instance,nodes,action_results_queue, type, opts={})
          @project = project
          @assembly_instance = assembly_instance
          @nodes = nodes
          @action_results_queue = action_results_queue 
          @type = type
          @filter = opts[:filter]

        end

        def initiate()
          test_components = get_test_components_with_stub()

          #Bakir new format for test; results;; it has theer attribute mapping
          #next need to get current values of components and run it through teh attribute mapping

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
        attr_reader :project,:assembly_instance, :nodes, :action_results_queue, :type, :filter
        def get_test_components_with_stub()
          if linked_tests_array = get_test_components()
            #Bakir; havent determined exact flow put here calling stub functioon that processes
            # each linked test; intent is to get the attributes for the test components; right now just calling 
            #/wo returning anything back and instead printing out partial results
            test_components = []
            linked_tests_array.each do |linked_tests|
              test_params = linked_tests.find_test_parameters
              #Bakir: test_params is currently mocked, need to fix find_test_parameters method to retrieve actual test params
              test_params = [{'mongodb.port'=>'mongodb_test__network_port_check.mongo_port'}]
              test_params.each do |params|
                k, v = params.first
                component_name = v.split(".").first
                test_components << { :test_component_name => component_name, :destination_node_id => linked_tests.node[:id] }
              end
            end

            #Bakir: test_components array should now have list of all test components that are related. Add them to service instance
            test_components.uniq!
            test_components.each do |test_comp| 
              sp_hash = {
                :cols => Component.common_columns,
                :filter => [:and, [:eq,:project_project_id,project.id],[:eq,:component_type,test_comp[:test_component_name]]]
              }
              test_comp_list = Model.get_objs(assembly_instance.model_handle(:component),sp_hash)
              #Select test component that belongs to this same assembly id or if it is nil, but filter out same test components that belong to other assemblies
              #RICH-SMOKETEST wasnt sure what test_comp_list.select! line was for
              test_comp_list.select! { |tstcmp| tstcmp[:assembly_id] == nil || tstcmp[:assembly_id] == assembly_instance[:id]  }
              #RICH-SMOKETEST shouldnt be adding test components to teh assembly; instead after finding test components
              # need to just find their paramterization
              #also right now if you run this twice you get:
              #an error like
              #constraint violation: Only one component of type mongodb_test__network_port_check can be on a node
              add_component_to_assembly_instance(test_comp[:destination_node_id], test_comp_list.first[:id])
            end
            #RICH-SMOKETEST: BY putting the test component module in teh version_conetxt they will be copied over; tehy wil be on the node under the directory associated with the test module, not the module on component the tets are linked to
            #For Rich: Now we need mechanism to copy test component modules to the node so their serverspec tests could be executed
#rich: the tests should be copied over by the same mechanism that copies ove component modules; 
#by setting version context above to test modules this will be achieved
            #Also we need logic to check that only when tests are run for the first time, execute-test will copy these modules and not to do that every time
            #If user adds new component which has tests related to it and subsequently needs loading and copying of tests to the node, we can trigger this again

            #For Rich: Finally, when test component modules have been copied to the node, we will get attribute data for test components and form 
            #similar hash return value which we have below with all needed data for execute-test agent
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

        def add_component_to_assembly_instance(node_id, test_component_id)
          node_idh = assembly_instance.model_handle().createIDH(:model_name => :node, :id => node_id)
          cmp_id = assembly_instance.model_handle().createIDH(:model_name => :component_template, :id => test_component_id).create_object()
          assembly_instance.add_component(node_idh, cmp_id, nil)
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

