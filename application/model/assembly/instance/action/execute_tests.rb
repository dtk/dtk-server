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
          version_contexts = get_version_contexts(test_components)
          test_cmps_with_version_contexts = test_components.each { |cmp| cmp[:version_context] = 
            version_contexts.select { |vc| cmp[:implementation_id] == vc[:id] }.first}

          output_hash = {
            :test_instances => []
          }

          test_cmps_with_version_contexts.each do |hash|
            attrib_array = Array.new
            hash[:attributes].each { |attrib| attrib_array << {:display_name=>attrib[:display_name], :value=>attrib[:value_asserted] }}
            output_hash[:test_instances] << { 
              :module_name => hash[:version_context][:display_name], 
              :component => "#{hash[:node_name]}/#{hash[:component_name]}",
              :test_component => hash[:display_name],
              :test_name => "network_port_check_spec.rb", #Currently hardcoded but should be available on test component level
              :params => attrib_array
            }
          end

          pp [:debug_output_hash, output_hash]
=begin
BAKIR: Output hash has this form
[:debug_output_hash,
 {:test_instances=>
   [{:module_name=>"mongodb_test",
     :component=>"mongodb/node1",
     :test_component=>"mongodb_test__network_port_check",
     :test_name=>"network_port_check_spec.rb",
     :params=>
      [{:display_name=>"mongo_port", :value=>nil},
       {:display_name=>"mongo_web_port", :value=>"28017"}]}]}]
=end  
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
          unless output_hash.empty?
            nodes.each do |node|
              components_array = []
              output_hash[:test_instances].each do |comp|
                if comp[:component].include? "#{node[:display_name]}/"
                  components_array << comp
                  components_including_node_name << comp
                end
              end
              node_hash[node[:id]] = {:components => components_array, :instance_id => node[:external_ref][:instance_id], :version_context => version_contexts}
            end
          end
          
          #components_including_node_name array will be empty if execute-test agent is triggered from specific node context
          if components_including_node_name.empty?
            components = filter[:components] #TODO: temp
            CommandAndControl.request__execute_action(:execute_tests_v2,:execute_tests_v2,nodes,callbacks, {:components => components, :version_context => version_contexts})
          else
            CommandAndControl.request__execute_action_per_node(:execute_tests_v2,:execute_tests_v2,node_hash,callbacks)
          end
        end
       private
        attr_reader :project,:assembly_instance, :nodes, :action_results_queue, :type, :filter
        def get_test_components_with_stub()
          if linked_tests_array = get_test_components()
            test_components = []
            test_params = []
            linked_tests_array.each do |linked_tests|
              linked_test_data = linked_tests.find_test_parameters.var_mappings_hash
              linked_test_data[:node_data] = linked_tests.node
              linked_test_data[:component_data] = linked_tests.component
              test_params << linked_test_data
              test_params.each do |params|
                k, v = params.first
                component_name = v.split(".").first
                test_components << { :test_component_name => component_name, :component_name => params[:node_data][:display_name], :node_name => params[:component_data][:display_name] }
              end
            end

            #Bakir: test_components array should now have list of all test components that are related. Add them to service instance
            test_components.uniq!
            test_comp_list = []
            test_components.each do |test_comp| 
              sp_hash = {
                :cols => Component.common_columns,
                :filter => [:and, [:eq,:project_project_id,project.id],[:eq,:component_type,test_comp[:test_component_name]]]
              }
              test_comp_list = Model.get_objs(assembly_instance.model_handle(:component),sp_hash)
              test_comp_list.each do |tst|
                tst[:component_name] = test_comp[:component_name]
                tst[:node_name] = test_comp[:node_name]
              end

              #RICH-SMOKETEST wasnt sure what test_comp_list.select! line was for
              #BAKIR: There is a possibility that test components with same name can be found on different assemblies. We want to pick test component that is either part of existing assembly or it is never added to the assembly and assembly_id is nil
              test_comp_list.select! { |tstcmp| tstcmp[:assembly_id] == nil || tstcmp[:assembly_id] == assembly_instance[:id]  }
            end
            #RICH-SMOKETEST: BY putting the test component module in teh version_conetxt they will be copied over; tehy wil be on the node under the directory associated with the test module, not the module on component the tets are linked to
            #rich: the tests should be copied over by the same mechanism that copies ove component modules; 
            #by setting version context above to test modules this will be achieved
          end 

          cmps = []
          test_comp_list.each do |cmp|
            sp_hash = {
              :cols => Attribute.common_columns,
              :filter => [:eq,:component_component_id,cmp[:id]]
            }
            attributes = Model.get_objs(assembly_instance.model_handle(:attribute),sp_hash)
            cmp[:attributes] = attributes
            cmps << cmp
          end

          return cmps
        end

        def get_test_components()
          Component::Test.get_linked_tests(assembly_instance)
        end

        def get_version_contexts(test_components)
          version_contexts = 
            unless test_components.empty?
              ComponentModule::VersionContextInfo.get_in_hash_form_from_templates(test_components)
            else
              Log.error("Unexpected that test_components is empty")
              nil
            end
          pp [:debug_version_context,version_contexts]
          return version_contexts
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

