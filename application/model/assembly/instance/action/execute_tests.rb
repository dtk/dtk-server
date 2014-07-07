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
          test_components = get_test_components_with_bindings()
          if test_components.empty?
            return
          end

          version_contexts = get_version_contexts(test_components)
          test_cmps_with_version_contexts = test_components.each do |cmp| 
            cmp[:version_context] = version_contexts.find { |vc| cmp[:implementation_id] == vc[:id] }
          end

          output_hash = {
            :test_instances => []
          }

          test_cmps_with_version_contexts.each do |hash|
            attrib_array = Array.new
            hash[:attributes].each { |attrib| attrib_array << { attrib[:display_name].to_sym =>attrib[:value_asserted] }}
            output_hash[:test_instances] << {
              :module_name => hash[:version_context][:implementation],
              :component => "#{hash[:node_name]}/#{hash[:component_name]}",
              :test_component => hash[:display_name],
              :test_name => "network_port_check_spec.rb", #Currently hardcoded but should be available on test component level
#              :test_name => "datanode_spec.rb",
              :params => attrib_array
            }
          end
          node_ids_with_tests = test_components.inject(Hash.new){|h,tc|h.merge(tc[:node_id] => true)}.keys
          action_results_queue.set_indexes!(node_ids_with_tests)
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
        # returns array of augmented (test) components where augmented data 
        # {:attributes => ARRAY[attribute objs),
        #  :node_name => STRING #node associated with base component name
        #  :node_id => ID
        #  :component_name => STRING #base component name
        #  :component_id => ID
        # there can be multiple entries for same test component for each base component instance 
        def get_test_components_with_bindings()
          ret = Array.new
          test_cmp_attrs = get_test_component_attributes()
          if test_cmp_attrs.empty?
            return ret
          end

          #get info about each test component
          sp_hash = {
            :cols => [:id,:group_id,:display_name,:attributes,:component_type],
            :filter => [:and, 
                        [:eq,:assembly_id,nil],
                        [:eq,:project_project_id,project.id],
                        [:oneof,:component_type,test_cmp_attrs.map{|t|t[:test_component_name]}]]
          }
          ndx_test_cmps = Hash.new #test cmps indexed by component type
          Model.get_objs(assembly_instance.model_handle(:component),sp_hash).each do |r|
            ndx = r[:component_type]
            cmp = ndx_test_cmps[ndx] ||= r.hash_subset(:id,:group_id,:display_name,:component_type).merge(:attributes => Array.new)
            cmp[:attributes] << r[:attribute]
          end

          # for each binding return at top level the matching test component with attributes substituted with binding value
          # and augmented columns :node_name and component_name
          test_cmp_attrs.each do |r|
            ndx = test_component_name = r[:test_component_name]
            test_cmp = ndx_test_cmps[ndx]
            unless test_cmp
              Log.error("Dangling reference to test components (#{test_component_name})")
            else
              #substitue in values from test_cmp_attrs               
              ret << dup_and_substitute_attribute_values(test_cmp,r)
            end
          end
          ret
        end

        def dup_and_substitute_attribute_values(test_cmp,attr_info)
          ret = test_cmp.shallow_dup(:display_name,:component_type)
          ret.merge!(Aux.hash_subset(attr_info,[:component_name,:component_id,:node_name,:node_id]))
          ret[:attributes] = test_cmp[:attributes].map do |attr|
            attr_dup = attr.shallow_dup(:display_name)
            attr_name = attr_dup[:display_name]
            if matching_attr = attr_info[:attributes].find{|a|a[:related_test_attribute] == attr_name}
              attr_dup[:value_asserted] = matching_attr[:component_attribute_value]
            end
            attr_dup
          end
          ret
        end


        # returns array having test components that are linked to a component in assembly_instance
        # each element has form
        # {:test_component_name=>String,
        #  :test_component_id=>ID,
        #  :component_name=>String,
        #  :node_name=>String,
        #  :attributes=>[{:component_attribute_name=>String, :component_attribute_value=>String,:related_test_attribute=>String}
        def get_test_component_attributes()
          ret = Array.new
          linked_tests = Component::Test.get_linked_tests(assembly_instance)
          if linked_tests.empty?
            return ret
          end

          test_params = linked_tests.map do |t|
            var_mappings = t.find_test_parameters.var_mappings_hash
            var_mappings.merge(:node_data => t.node, :component_data => t.component)
          end
            
          attr_mh = assembly_instance.model_handle(:attribute)
          test_params.map do |params|
            k, v = params.first
            related_test_attribute = v.map { |x| x.split(".").last }
            test_component_name = v.map { |x| x.split(".").first }.first
            attribute_names = k.map { |x| x.split(".").last }
            component_id = params[:component_data][:id]
            #TODO: more efficient to get in bulk outside of test_params loop
            sp_hash = {
              :cols => [:display_name, :value_asserted],
              :filter => [:and,
                          [:eq, :component_component_id,component_id],
                          [:oneof, :display_name, attribute_names]]
            }
            ndx_attr_vals  = Model.get_objs(attr_mh,sp_hash).inject(Hash.new) do |h,a|
              h.merge(a[:display_name] => a[:value_asserted])
            end
            attributes = Array.new
            attribute_names.each_with_index do |attribute_name, idx|
              if val = ndx_attr_vals[attribute_name]
                attributes << {
                  :component_attribute_name => attribute_name,
                  :component_attribute_value => val,
                  :related_test_attribute => related_test_attribute[idx] 
                }
              end
            end
            { 
              :test_component_name => test_component_name, 
              :attributes => attributes, 
              :component_id => params[:component_data][:id],
              :component_name => params[:component_data][:display_name], 
              :node_id => params[:node_data][:id],
              :node_name => params[:node_data][:display_name]
            }
          end
        end

        def get_version_contexts(test_components)
          version_contexts =
            unless test_components.empty?
              ComponentModule::VersionContextInfo.get_in_hash_form_from_templates(test_components)
            else
              Log.error("Unexpected that test_components is empty")
              nil
            end
          version_contexts
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

