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
      def self.create_from_hash(hash,task_idh)
        hash[:component] &&= Component.create_from_model_handle(hash[:component],task_idh.createMH(:component))
        if attrs = hash[:attributes]
          attr_mh = task_idh.createMH(:attribute)
          attrs.each_with_index{|attr,i|attrs[i] = Attribute.create_from_model_handle(attr,attr_mh)}
        end
        new(hash)
      end

      def self.order_and_group_by_component(state_change_list)
        ndx_cmp_idhs = Hash.new
        node = state_change_list.first[:node]
        state_change_list.each do |sc|
          cmp = sc[:component]
          ndx_cmp_idhs[cmp[:id]] ||= cmp.id_handle() 
        end
        cmp_deps = Component.get_component_type_and_dependencies(ndx_cmp_idhs.values)
        cmp_order = get_component_order(cmp_deps, node)
        cmp_order.map do |(component_id,deps)|
          create_from_state_change(state_change_list.select{|a|a[:component][:id] == component_id},deps) 
        end
      end

      # Amar
      # Return order from node table if order is consistent, otherwise generate order through TSort and update order in table
      def self.get_component_order(cmp_deps, node)
        cmp_ids_with_deps = get_cmp_ids_with_deps(cmp_deps)
        # Get order from DB
        cmp_order = node.get_ordered_component_ids()
        # return if consistent
        # DEBUG SNIPPET
        require 'rubygems'
        require 'ap'
        ap "s_order_consistent?(cmp_ids_with_deps, cmp_order)"
        ap is_order_consistent?(cmp_ids_with_deps, cmp_order)
        return cmp_order if is_order_consistent?(cmp_ids_with_deps, cmp_order)

        # generate order via TSort
        cmp_order = generate_component_order(cmp_ids_with_deps)
        # update order in node table
        node.update_ordered_component_ids(cmp_order)
        ap "cmp_order"
        ap cmp_order
        return cmp_order
      end

      # Amar: Checking if existing order in node table is consistent
      def self.is_order_consistent?(cmp_ids_with_deps, order)
        return false if order.empty?
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
        return cmp_ids_with_deps
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
        self.new(hash)
      end
    end
  end
end; end
