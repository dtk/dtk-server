module XYZ
  class Assembly < Component

    #### for cloning
    def add_model_specific_override_attrs!(override_attrs,target_obj)
      override_attrs[:display_name] ||= SQL::ColRef.qualified_ref 
      override_attrs[:updated] ||= false
    end

    ##############
    def get_node_assembly_nested_objects()
      ndx_nodes = Hash.new
      sp_hash = {:cols => [:node_assembly_nested_nodes_and_cmps]}
      node_col_rows = get_objs(sp_hash)
      node_col_rows.each do |r|
        n = r[:node].materialize!(Node.common_columns)
        node = ndx_nodes[n[:id]] ||= n.merge(:components => Array.new)
        node[:components] << r[:nested_component].materialize!(Component.common_columns())
      end

      nested_node_ids = ndx_nodes.keys
      sp_hash = {
        :cols => Port.common_columns(),
        :filter => [:oneof, :node_node_id, nested_node_ids]
      }
      port_rows = Model.get_objs(model_handle(:port),sp_hash)
      port_rows.each do |r|
        node = ndx_nodes[r[:node_node_id]]
        (node[:ports] ||= Array.new) << r.materialize!(Port.common_columns())
      end
      sp_hash = {
        :cols => PortLink.common_columns(),
        :filter => [:eq, :assembly_id, id()]
      }
      port_links = Model.get_objs(model_handle(:port_link),sp_hash)
      port_links.each{|pl|pl.materialize!(PortLink.common_columns())}
      {:nodes => ndx_nodes.values, :port_links => port_links}
    end

    def is_assembly?()
      true
    end
    def assembly_type()
      #TODO: stub; may use basic_type to distinguish between component and node assemblies
      :node
    end
    def is_base_component?()
      nil
    end

    def self.db_rel()
      Component.db_rel()
    end

    def get_component_with_attributes_unraveled(attr_filters={})
      attr_vc = "#{assembly_type()}_assembly_attributes".to_sym
      sp_hash = {:columns => [:id,:display_name,:component_type,:basic_type,attr_vc]}
      component_and_attrs = get_objects_from_sp_hash(sp_hash)
      return nil if component_and_attrs.empty?
      sample = component_and_attrs.first
      #TODO: hack until basic_type is populated
      #component = sample.subset(:id,:display_name,:component_type,:basic_type)
      component = sample.subset(:id,:display_name,:component_type).merge(:basic_type => "#{assembly_type()}_assembly")
      node_attrs = {:node_id => sample[:node][:id], :node_name => sample[:node][:display_name]} 
      filtered_attrs = component_and_attrs.map do |r|
        attr = r[:attribute]
        if attr and not attribute_is_filtered?(attr,attr_filters)
          cmp = r[:sub_component]
          cmp_attrs = {:component_type => cmp[:component_type],:component_name => cmp[:display_name]}
          attr.merge(node_attrs).merge(cmp_attrs)
        end
      end.compact
      attributes = AttributeComplexType.flatten_attribute_list(filtered_attrs)
      component.merge(:attributes => attributes)
    end
  end
end
