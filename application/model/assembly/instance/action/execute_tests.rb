# -*- coding: utf-8 -*-
module DTK
  class Assembly::Instance
    module Action
      class ExecuteTests < ActionResultsQueue
        attr_reader :error
        def initialize(params)
          super()
          @agent_action = params[:agent_action]
          @project = params[:project]
          @assembly_instance = params[:assembly_instance]
          @nodes = params[:nodes]
          @type = :assembly
          @filter = params[:component]
          @error = nil
        end

        def initiate
          test_cmps = get_test_components_with_bindings()
          if test_cmps.empty?
            @error = 'Unable to execute tests. There are no links to test components!'
            raise ::DTK::ErrorUsage
          end

          # Recognize if nodes are part of node group and map test components to nodes appropriately
          node_names = @nodes.map { |n| { name: n[:display_name], id: n[:id]} }
          test_components = []
          test_cmps.each do |tc|
            node_names.each do |node|
              if node[:name].split('::').last.split(':').first == tc[:node_name]
                out = tc.dup
                out[:node_name] = node[:name]
                out[:node_id] = node[:id]
                test_components << out
              else
                test_components << tc
              end
            end
          end
          test_components.uniq!

          test_components.select! { |tc| node_names.map{|n| n[:name]}.include? tc[:node_name] }

          ndx_version_contexts = get_version_contexts(test_components).inject({}){|h,vc|h.merge(vc[:id]=>vc)}
          version_contexts = ndx_version_contexts.values

          test_instances = test_components.map do |test_cmp|
            unless version_context = ndx_version_contexts[test_cmp[:implementation_id]]
              raise Error.new("Cannot find version context for #{test_cmp[:dispaly_name]}")
            end
            attrib_array = test_cmp[:attributes].map{|a|{a[:display_name].to_sym =>a[:attribute_value]}}
            test_name = (test_cmp[:external_ref]||{})[:test_name]
            {
              module_name: version_context[:implementation],
              component: "#{test_cmp[:node_name]}/#{test_cmp[:component_name]}",
              test_component: test_cmp[:display_name],
              test_name: test_name,
              params: attrib_array
            }
          end

          node_ids_with_tests = test_components.inject({}){|h,tc|h.merge(tc[:node_id] => true)}.keys
          ndx_pbuilderid_to_node_info = nodes.inject({}) do |h,n|
            h.merge(n.pbuilderid => {id: n[:id].to_s, display_name: n[:display_name]})
          end

          # filter nodes with tests
          nodes.select! { |node| node_ids_with_tests.include? node[:id]}

          # part of the code used to decide which components belong to which nodes.
          # based on that fact, serverspec tests will be triggered on node only for components that actually belong to that specific node
          node_hash = {}
          unless test_instances.empty?
            nodes.each do |node|
              components_array = []
              test_instances.each do |comp|
                if comp[:component].include? node[:display_name]
                  components_array << comp
                end
              end
              node_hash[node[:id]] = {components: components_array, instance_id: node[:external_ref][:instance_id], version_context: version_contexts}
            end
          end

          # we send elements that are going to be used, due to bad design we need to send an array even
          # if queue logic is only using size of that array.
          set_indexes!(node_hash.keys)

          callbacks = {
            on_msg_received: proc do |msg|
              response = CommandAndControl.parse_response__execute_action(nodes,msg)
              if response && response[:pbuilderid] && response[:status] == :ok
                node_info = ndx_pbuilderid_to_node_info[response[:pbuilderid]]
                raw_data = response[:data].map{|r|node_info.merge(r)}
                #TODO: find better place to put this
                raw_data.each do |r|
                  if r[:component_name]
                    r[:component_name].gsub!(/__/,'::')
                  end
                  if r[:test_component_name]
                    r[:test_component_name].gsub!(/__/,'::')
                  end
                end
                #just for a safe side to filter out empty response, it causes further an error on the client side
                unless response[:data].empty? || response[:data].nil?
                  packaged_data = DTK::ActionResultsQueue::Result.new(node_info[:display_name],raw_data)
                  push(node_info[:id], (type == :node) ? packaged_data.data : packaged_data)
                end
              end
            end
          }

          Log.info_pp(execute_tests_v2: node_hash)
          CommandAndControl.request__execute_action_per_node(:execute_tests_v2,:execute_tests_v2,node_hash,callbacks)
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
        def get_test_components_with_bindings
          ret = []
          test_cmp_attrs = get_test_component_attributes()
          if test_cmp_attrs.empty?
            return ret
          end
          # for each binding return at top level the matching test component with attributes substituted with binding value
          # and augmented columns :node_name and component_name
          test_cmp_attrs.each do |r|
            if test_cmp = r[:test_component]
              #substitute in values from test_cmp_attrs
              ret << dup_and_substitute_attribute_values(test_cmp,r)
            else
              Log.error("Dangling reference to test components (#{test_component_name})")
            end
          end
          ret
        end

        def dup_and_substitute_attribute_values(test_cmp,attr_info)
          ret = test_cmp.shallow_dup(:display_name,:component_type,:external_ref)
          ret.merge!(Aux.hash_subset(attr_info,[:component_name,:component_id,:node_name,:node_id]))
          ret[:attributes] = test_cmp[:attributes].map do |attr|
            attr_dup = attr.shallow_dup(:display_name)
            attr_name = attr_dup[:display_name]
            if matching_attr = attr_info[:attributes].find{|a|a[:related_test_attribute] == attr_name}
              attr_dup[:attribute_value] = matching_attr[:component_attribute_value]
            end
            attr_dup
          end
          ret
        end

        # returns array having test components that are linked to a component in assembly_instance
        # each element has form
        # {:test_component=>Cmp Obj
        #  :component_name=>String,
        #  :node_name=>String,
        #  :attributes=>[{:component_attribute_name=>String, :component_attribute_value=>String,:related_test_attribute=>String}
        def get_test_component_attributes
          ret = []
          linked_tests = Component::Test.get_linked_tests(assembly_instance, @project, @filter)
          if linked_tests.empty?
            return ret
          end

          attr_mh = assembly_instance.model_handle(:attribute)
          all_test_params = []

          linked_tests.each do |t|
            node = t.node
            component = t.component
            component_id = component.id
            linked_test_array = t.find_relevant_linked_test_array()

            linked_test_array.each do |linked_test|
              var_mappings_hash = linked_test.var_mappings_hash
              k, v = var_mappings_hash.first
              related_test_attribute = v.map { |x| x.split('.').last }
              attribute_names = k.map { |x| x.split('.').last }
              test_component = linked_test.test_component
              # TODO: more efficient to get in bulk outside of test_params loop
              sp_hash = {
                cols: [:display_name, :attribute_value],
                filter: [:and,
                         [:eq, :component_component_id,component_id],
                         [:oneof, :display_name, attribute_names]]
              }
              ndx_attr_vals  = Model.get_objs(attr_mh,sp_hash).inject({}) do |h,a|
                h.merge(a[:display_name] => a[:attribute_value])
              end
              attributes = []

              attribute_names.each_with_index do |attribute_name, idx|
                if val = ndx_attr_vals[attribute_name]
                  attributes << {
                    component_attribute_name: attribute_name,
                    component_attribute_value: val,
                    related_test_attribute: related_test_attribute[idx]
                  }
                end
              end
              hash = {
                test_component: test_component,
                attributes: attributes,
                component_id: component_id,
                component_name: component[:display_name],
                node_id: node[:id],
                node_name: node[:display_name]
              }
              all_test_params << hash
            end
          end
          all_test_params
        end

        def get_version_contexts(test_components)
          unless test_components.empty?
            TestModule::VersionContextInfo.get_in_hash_form(test_components,@assembly_instance)
          else
            Log.error('Unexpected that test_components is empty')
            nil
          end
        end

        #TODO: deprecate
        #TODO: rather than passing in strings, have controller/helper methods convert to ids and objects, rather than passing
        def get_augmented_component_templates(nodes,components)
          ret = []
          if nodes.empty?
            return ret
          end

          sp_hash = {
            cols: [:id,:group_id,:instance_component_template_parent,:node_node_id],
            filter: [:oneof,:node_node_id,nodes.map(&:id)]
          }
          ret = Model.get_objs(nodes.first.model_handle(:component),sp_hash).map do |r|
            r[:component_template].merge(node_node_id: r[:node_node_id], component_instance_id: r[:id])
          end
          if components.nil? || components.empty? or !components.include? '/'
            return ret
          end

          cmp_node_names = components.map do |name_pairs|
            if name_pairs.include? '/'
              split = name_pairs.split('/')
                if split.size == 2
                  {node_name: split[0],component_name: Component.display_name_from_user_friendly_name(split[1])}
                else
                  Log.error("unexpected component form: #{name_pairs}; skipping")
                  nil
                end
            else
                {component_name: Component.display_name_from_user_friendly_name(name_pairs)}
            end
          end.compact
          ndx_node_names = nodes.inject({}){|h,n|h.merge(n[:id] => n[:display_name])}

          #only keep matching ones
          ret.select do |cmp_template|
            cmp_node_names.find do |r|
              r[:node_name] == ndx_node_names[cmp_template[:node_node_id]] && r[:component_name] == cmp_template[:display_name]
            end
          end
        end
      end
    end
  end
end
