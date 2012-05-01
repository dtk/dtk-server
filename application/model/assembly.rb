r8_nested_require('assembly','attribute_pattern')
module XYZ
  class Assembly < Component
    def self.list_from_library(assembly_mh,library_idh=nil)
      lib_filter = (library_idh ? [:eq, :library_library_id, library_idh.get_id()] : [:neq, :library_library_id, nil])
      sp_hash = {
        :cols => [:id, :display_name,:nested_nodes_and_cmps_summary],
        :filter => [:and, [:eq, :type, "composite"], lib_filter]
      }
      assemblies = get_objs(assembly_mh,sp_hash)
      list_aux(assemblies)
    end

    def self.list_from_target(assembly_mh,target_idh=nil)
      target_filter = (target_idh ? [:eq, :datacenter_datacenter_id, target_idh.get_id()] : [:neq, :datacenter_datacenter_id, nil])
      sp_hash = {
        :cols => [:id, :display_name,:nested_nodes_and_cmps_summary],
        :filter => [:and, [:eq, :type, "composite"], target_filter]
      }
      assemblies = get_objs(assembly_mh,sp_hash)
      list_aux(assemblies)
    end

    def set_attributes(pattern,value)
      ret = Array.new
      pattern = AssemblyAttributePattern.create(pattern)
      attr_idhs = pattern.ret_attribute_idhs(id_handle())
      return ret if attr_idhs.empty?

      attr_mh = model_handle(:attribute)
      attribute_rows = attr_idhs.map{|idh|{:id => idh.get_id(),:value_asserted => value}}
      Attribute.update_and_propagate_attributes(attr_mh,attribute_rows)
      attr_idhs
    end

    class << self
      private
      def list_aux(assemblies)
        ndx_ret = Hash.new
        assemblies.each do |r|
          #TODO: hack to create a Assembly object (as opposed to row which is component); should be replaced by having 
          #get_objs do this (using possibly option flag for subtype processing)
          pntr = ndx_ret[r[:id]] ||= r.id_handle.create_object().merge(:display_name => r[:display_name], :ndx_nodes => Hash.new)
          node_id = r[:node][:id]
          node = pntr[:ndx_nodes][node_id] ||= {:node_name => r[:node][:display_name], :node_id => node_id, :components => Array.new}
          if r[:nested_component][:component_type]
            node[:components] << r[:nested_component][:component_type].gsub(/__/,"::")
          end
        end
        
        ndx_ret.values.map do |r|
          {:id => r[:id], :display_name => r[:display_name], :nodes => r[:ndx_nodes].values}
        end
      end
    end

    def self.delete_from_library(assembly_idh)
      #need to explicitly delete nodes, but not components since node's parents are not the assembly, while compoennt's parents are teh nodes
      sp_hash = {
        :cols => [:id, :nodes],
        :filter => [:eq, :id, assembly_idh.get_id]
      }
      node_idhs = get_objs(assembly_idh.createMH(),sp_hash).map{|r|r[:node].id_handle()}
      Model.delete_instances(node_idhs + [assembly_idh])
    end

    #### for cloning
    def add_model_specific_override_attrs!(override_attrs,target_obj)
      override_attrs[:display_name] ||= SQL::ColRef.qualified_ref 
      override_attrs[:updated] ||= false
    end

    ##############
    def get_node_assembly_nested_objects()
      ndx_nodes = Hash.new
      sp_hash = {:cols => [:nested_nodes_and_cmps]}
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

    #TODO: can we avoid explicitly pacing this here
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
