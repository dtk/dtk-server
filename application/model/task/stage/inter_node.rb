# TODO AMAR: Following case is possibly a bug: n1=[c1[c2],c3[c1]] n2=[c2]. c3 should be moved into stage2 along with c1.
# CHECK ALGORITHM OF THIS CASE
module DTK
  module Stage
    class InterNode
      # Generating stages in case of inter node component dependencies 
      def self.generate_stages(state_change_list,assembly)
        
        # If 'GUARDS' temporal mode set, don't generate stages workflow
        return [state_change_list] unless Workflow.stages_mode?
        
        stages = Array.new
        nodes = Array.new
        
        # Rich: get_internode_dependencies will do things that are redundant with what is below, but should be acceptable for now
        internode_dependencies = get_internode_dependencies(state_change_list,assembly)
        return [state_change_list] if internode_dependencies.empty?
        
        state_change_list.each do |node_change_list|
          ndx_cmp_idhs = Hash.new
          node_id = node_change_list.first[:node][:id]
          
          # Gathering all impl ids to get loaded in first config node stage
          impl_ids_list = Array.new
          node_change_list.each { |sc| impl_ids_list << sc[:component][:implementation_id] }
          
          node_change_list.each do |sc|
            cmp = sc[:component]
            ndx_cmp_idhs[cmp[:id]] ||= cmp.id_handle() 
            
            # Adding impl_ids_list to each node
            sc[:node][:implementation_ids_list] = impl_ids_list
          end
          components = Component::Instance.get_components_with_dependency_info(ndx_cmp_idhs.values)
          cmp_deps = ComponentOrder.get_ndx_cmp_type_and_derived_order(components)
          cmp_ids_with_deps = Task::Action::OnComponent.get_cmp_ids_with_deps(cmp_deps)
          
          nodes << { :node_id => node_id, :component_dependency => cmp_ids_with_deps }
        end
        
        stages << clean_dependencies_that_are_internode(internode_dependencies, nodes)
        # everything in each stage can be executed concurrently, but each stage must go sequentially
        prev_deps_count = internode_dependencies.size
        while stage = generate_stage(internode_dependencies)
          # Checks for inter node dependency cycle and throws error if cycle present
          prev_deps_count = detect_internode_cycle(internode_dependencies, prev_deps_count)
          stages << stage 
        end
        populate_stages_data(stages, state_change_list)
      end
      
     private
      def self.get_internode_dependencies(state_change_list,assembly)
        deps = get_internode_dependencies__guards(state_change_list) 
        deps + get_internode_dependencies__port_link_order(state_change_list,assembly,deps)
      end
      
      def self.get_internode_dependencies__guards(state_change_list)
        ret = Array.new
        aug_attr_list = Attribute.aug_attr_list_from_state_change_list(state_change_list)
        guard_rels = Array.new
        Attribute.dependency_analysis(aug_attr_list) do |attr_in,link,attr_out|
          if attr_guard = GuardedAttribute.create(attr_in,link,attr_out)
            guard = attr_guard[:guard]
            guarded = attr_guard[:guarded]
            cmp_dep = {
              :guard => {:component => guard[:component], :node => guard[:node]},
              :guarded => {:component => guarded[:component], :node => guarded[:node]}
            }
            #guarded has to go after guard
            #flat list of dependencies as oppossed to collecting all deps for one component
            #attr_guard has relationship between attributes; stripping out attr info; consequently same compoennt relationship can be in more than once
            guard_rels << cmp_dep
          end
        end
        
        # Amar: output format
        guard_rels.map do |dep|
          {
            :node_dependency => { dep[:guarded][:node][:id] => dep[:guard][:node][:id] },
            :node_dependency_names => { dep[:guarded][:node][:display_name] => dep[:guard][:node][:display_name] },
            :component_dependency => { dep[:guarded][:component][:id] => [dep[:guard][:component][:id]] },
            :component_dependency_names => { dep[:guarded][:component][:display_name] => [dep[:guard][:component][:display_name]] }
          }
        end
      end
      
      def self.get_internode_dependencies__port_link_order(state_change_list,assembly,existing_deps)
        ret = Array.new
        #TODO: should we filter by members of state_change_list
        ordered_port_links = assembly.get_port_links(:filter => [:neq,:temporal_order,nil])
        return ret if ordered_port_links.empty?
        sp_hash = {
          :cols => [:ports,:temporal_order],
          :filter => [:oneof, :id, ordered_port_links.map{|r|r.id}]
        }
        aug_port_links = Model.get_objs(assembly.model_handle(:port_link),sp_hash)
        ndx_scs = Hash.new
        state_change_list.flatten(1).each do |sc|
          if sc[:type] == "converge_component"
            node = sc[:node]
            cmp = sc[:component]
            unless node and cmp
              Log.error("Unexpected that node or cmp is nil")
              next
            end
            (ndx_scs[node[:id]] ||= Hash.new)[cmp[:id]] = sc
          end
        end
        aug_port_links.map do |pl|
          before_index = DirIndex[pl[:temporal_order].to_sym][:before_sc]
          after_index = DirIndex[pl[:temporal_order].to_sym][:after_sc]
          before_sc = (ndx_scs[pl[before_index][:node_id]]||{})[pl[before_index][:component_id]]
          after_sc = (ndx_scs[pl[after_index][:node_id]]||{})[pl[after_index][:component_id]]
          unless before_sc and after_sc
            Log.error("Unexpected that cannot find the input and output statae changes")
            nil
          else
            #TODO: see if for component should instead use :component_type; what about also using 'title' for non-singletons? 
            {
              :node_dependency => { after_sc[:node][:id] => before_sc[:node][:id] },
              :node_dependency_names => { after_sc[:node][:display_name] => before_sc[:node][:display_name] },
              :component_dependency => { after_sc[:component][:id] => [before_sc[:component][:id]] },
              :component_dependency_names => { after_sc[:component][:display_name] => [before_sc[:component][:display_name]] }
            }
          end
        end.compact
      end
      DirIndex = {
        :before => {:before_sc => :input_port,  :after_sc => :output_port},  
        :after =>  {:before_sc => :output_port, :after_sc => :input_port}  
      }
      
      def self.detect_internode_cycle(internode_dependencies, prev_deps_count)
        cur_deps_count = internode_dependencies.size
        if prev_deps_count == cur_deps_count
          # Gathering data for error's pretty print on CLI side
          cmp_dep_str = Array.new
          nds_dep_str = Array.new
          internode_dependencies.each do |dep|
            cmp_dep_str << "#{format_hash(dep[:component_dependency_names])} (#{format_hash(dep[:component_dependency])})"
            nds_dep_str << "#{format_hash(dep[:node_dependency_names])} (#{format_hash(dep[:node_dependency])})"
          end
          error_msg = "Inter-node components cycle detected.\nNodes cycle:\n#{nds_dep_str.join("\n")}\nComponents cycle:\n#{cmp_dep_str.join("\n")}"
          raise ErrorUsage.new(error_msg)
        end
        cur_deps_count
      end

      def self.format_hash(h)
        h.map{|k,v| "#{k} => #{v}"}.join(',')
      end
      
      # Populating stages from original data 'state_change_list'
      def self.populate_stages_data(stages, state_change_list)
        stages_state_change_list = Array.new
        first_stage = true
        stages.each do |stage|
          stage_scl = Array.new
          stage.each do |cmp|
            node_id = cmp[:node_id]
            in_node_scl = state_change_list.select { |n| n.first[:node][:id] == node_id }.first
            cmp_ids = cmp[:component_dependency].keys
            out_node_scl = Array.new
            cmp_ids.each do |cmp_id|
              in_node_scl.each do |in_node_cmp|
                if in_node_cmp[:component][:id] == cmp_id
                  # removing impl_ids_list from stages except from first stage. Component modules must be loaded only for first stage
                  in_node_cmp[:node][:implementation_ids_list] = Array.new unless first_stage
                  out_node_scl << in_node_cmp
                end
              end
            end
            stage_scl << out_node_scl
          end
          first_stage = false if first_stage
          stages_state_change_list << stage_scl
        end
        stages_state_change_list
      end
      
      # This method removes intranode dependency components from nodes and returns stage_1 actions
      def self.clean_dependencies_that_are_internode(internode_dependencies, nodes)
        nodes.each do |node|
          internode_dependencies.each do |internode_dependency|
            parent = internode_dependency[:component_dependency].keys.first
            if node[:component_dependency].keys.include?(parent)
              node[:component_dependency].delete(parent) 
            end
          end
        end
        nodes
      end
      
      # This method will remove and return stage elements from current 'internode_dependencies'
      # that are not depended on any component in current 'internode_dependencies'
      def self.generate_stage(internode_dependencies)
        # Return nil if all stages are generated
        return nil if internode_dependencies.empty?
        
        stage = Array.new
        internode_dependencies_to_rm = Array.new
        internode_dependencies.each do |internode_dependency|
          children = internode_dependency[:component_dependency].values.first
          if is_stage(internode_dependencies, children)
            internode_dependencies_to_rm << internode_dependency
            stage_element = {
              :component_dependency => internode_dependency[:component_dependency],
              :node_id => internode_dependency[:node_dependency].keys.first
            }
            stage << stage_element unless stage.include?(stage_element)
          end
        end
        internode_dependencies_to_rm.each { |rm| internode_dependencies.delete(rm) }
        
        stage
      end
      
      def self.is_stage(internode_dependencies, children)
        internode_dependencies.each do |internode_dependency|
          return false if children.include?(internode_dependency[:component_dependency].keys.first)
        end
        true
      end
    end
  end
end
