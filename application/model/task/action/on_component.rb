module DTK; class Task
  class Action 
    class OnComponent < HashObject
      def self.status(object,opts)
        if opts[:no_attributes]
          component_name(object)
        else
          ret = PrettyPrintHash.new
          ret[:component] = component_status(object,opts) 
          ret[:attributes] = attributes_status(object,opts) unless opts[:no_attributes]
          ret
        end
      end

      #for debugging
      def self.pretty_print_hash(object)
        ret = PrettyPrintHash.new
        ret[:component] = (object[:component]||{})[:display_name]

        #TODO: should get attribute values from attribute object since task info can be stale
        
        ret[:attributes]  = (object[:attributes]||[]).map do |attr|
          ret_attr = PrettyPrintHash.new
          ret_attr.add(attr,:display_name,:value_asserted,:value_derived)
        end
        ret
      end
      def self.create_from_hash(hash,task_idh=nil)
        if component = hash[:component]
          unless component.kind_of?(Component)
            unless task_idh
              raise Error.new("If hash[:component] is not of type Component then task_idh must be supplied")
            end
            hash[:component] = Component.create_from_model_handle(component,task_idh.createMH(:component))
          end
        end
        if attrs = hash[:attributes]
          unless attrs.empty?
            attr_mh = task_idh.createMH(:attribute)
            attrs.each_with_index{|attr,i|attrs[i] = Attribute.create_from_model_handle(attr,attr_mh)}
          end
        end
        new(hash)
      end

      #returns component_actions,intra_node_stages
      def self.order_and_group_by_component(state_change_list)
        intra_node_stages = nil
        ndx_cmp_idhs = Hash.new
        state_change_list.each do |sc|
          cmp = sc[:component]
          ndx_cmp_idhs[cmp[:id]] ||= cmp.id_handle() 
        end
        components = Component::Instance.get_components_with_dependency_info(ndx_cmp_idhs.values)
        cmp_deps = ComponentOrder.get_ndx_cmp_type_and_derived_order(components)
        if Workflow.intra_node_stages?
          cmp_order,intra_node_stages = get_intra_node_stages(cmp_deps, state_change_list)
        elsif Workflow.intra_node_total_order?
          node = state_change_list.first[:node]
          cmp_order = get_total_component_order(cmp_deps, node) 
        else
          raise Error.new("No intra node ordering strategy found")
        end
        component_actions = cmp_order.map do |(component_id,deps)|
          create_from_state_change(state_change_list.select{|a|a[:component][:id] == component_id},deps) 
        end
        [component_actions,intra_node_stages]
      end

      #returns cmp_ids_with_deps,intra_node_stages
      def self.get_intra_node_stages(cmp_deps, state_change_list)
        cmp_ids_with_deps = get_cmp_ids_with_deps(cmp_deps).clone
        cd_ppt_stgs, scl_ppt_stgs = Stage::PuppetStageGenerator.generate_stages(cmp_ids_with_deps.dup, state_change_list.dup)
        intra_node_stages = Array.new
        cd_ppt_stgs.each_with_index do |cd, i|
          cmp_ids_with_deps_ps = cd_ppt_stgs[i].dup
          state_change_list_ps = scl_ppt_stgs[i]
          intranode_stages_with_deps = Stage::IntraNode.generate_stages(cmp_ids_with_deps_ps, state_change_list_ps)
          intra_node_stages << intranode_stages_with_deps.map{|stage|stage.keys }
        end
        # Amar: to enable multiple puppet calls inside one puppet_apply agent call, 
        # puppet_stages are added to intra node stages. Check PuppetStageGenerator class docs for more details
        [cmp_ids_with_deps,intra_node_stages]
      end

      # Amar
      # Return order from node table if order is consistent, otherwise generate order through TSort and update order in table
      def self.get_total_component_order(cmp_deps, node)
        cmp_ids_with_deps = get_cmp_ids_with_deps(cmp_deps)
        # Get order from DB
        cmp_order = node.get_ordered_component_ids()
        # return if consistent
        return cmp_order if is_total_order_consistent?(cmp_ids_with_deps, cmp_order)

        # generate order via TSort
        cmp_order = generate_component_order(cmp_ids_with_deps)
        # update order in node table
        node.update_ordered_component_ids(cmp_order)
        return cmp_order
      end

      # Amar: Checking if existing order in node table is consistent
      def self.is_total_order_consistent?(cmp_ids_with_deps, order)
        return false if order.empty?
        return false unless cmp_ids_with_deps.keys.sort == order.sort
        begin
          cmp_ids_with_deps.map do |parent, children|  
            unless children.empty?
              children.each do |child|
                  return false if order.index(child) > order.index(parent) # inconsistent if any child order is after parent
              end
            end
          end
        rescue Exception => e
          return false
        end
        return true
      end

      def self.get_cmp_ids_with_deps(cmp_deps)
        #TODO: assumption that only a singleton component can be a dependency -> match on component_type sufficient
        #first build index from component_type to id
        cmp_type_to_id = Hash.new
        cmp_deps.each do |id,info|
          info[:component_dependencies].each do |ct|
            unless cmp_type_to_id.has_key?(ct)
              cmp_type_to_id[ct] = (cmp_deps.find{|id_x,info_x|info_x[:component_type] == ct}||[]).first
            end
          end
        end

        #note: dependencies can be omitted if they have already successfully completed; therefore only
        #looking for non-null deps
        cmp_ids_with_deps = cmp_deps.inject({}) do |h,(id,info)|
          non_null_deps = info[:component_dependencies].map{|ct|cmp_type_to_id[ct]}.compact
          h.merge(id => non_null_deps)
        end
        return cmp_ids_with_deps.nil? ? {} : cmp_ids_with_deps
      end

      #returns array of form [component_id,deps]
      def self.generate_component_order(cmp_ids_with_deps)
        ordered_cmp_ids = TSortHash.new(cmp_ids_with_deps).tsort
        ordered_cmp_ids.map do |cmp_id|
          [cmp_id,cmp_ids_with_deps[cmp_id]]
        end
        ordered_cmp_ids
      end

      def add_attribute!(attr)
        self[:attributes] << attr
      end

     private

      def self.component_name(object)
        ret = (object[:component]||{})[:display_name]
        ret && ret.gsub(/__/,"::")
      end

      def self.component_status(object,opts)
        ret = PrettyPrintHash.new
        if name = component_name(object)
          ret[:name] = name
        end
        component = object[:component]||{}
        if id = component[:id]  
          ret[:id] = id
        end
        ret
      end

      def self.attributes_status(object,opts)
        #need to query db to get up to date values
        (object[:attributes]||[]).map do |attr|
          ret_attr = PrettyPrintHash.new
          ret_attr[:name] = attr[:display_name]
          ret_attr[:id] = attr[:id]
          ret_attr[:value] = attr[:value_asserted]||attr[:value_derived]
          ret_attr
        end
      end

      def self.create_list_from_execution_blocks(exec_blocks,config_agent_type)
        exec_blocks.components.map do |cmp|
          hash = {
            :attributes => Array.new,
            :component => cmp,
            :on_node_config_agent_type => config_agent_type
          }
          new(hash)
        end
      end

      def self.create_from_state_change(scs_same_cmp,deps)
        state_change = scs_same_cmp.first
        #TODO: may deprecate need for ||[sc[:id]
        pointer_ids = scs_same_cmp.map{|sc|sc[:linked_ids]||[sc[:id]]}.flatten.compact
        hash = {
          :state_change_pointer_ids => pointer_ids, #this field used to update teh coorepdonsing state change after thsi action is run
          :attributes => Array.new,
          :component => state_change[:component],
          :on_node_config_agent_type => state_change.on_node_config_agent_type(),
        }
        hash.merge!(:component_dependencies => deps) if deps

        #TODO: can get more sophsiticated and handle case where some components installed and other are incremental
        incremental_change = !scs_same_cmp.find{|sc|not sc[:type] == "setting"}
        if incremental_change
          hash.merge!(:changed_attribute_ids => scs_same_cmp.map{|sc|sc[:attribute_id]}) 
        end
        new(hash)
      end
    end
  end
end; end
