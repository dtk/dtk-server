module DTK; class Node
  class NodeAttribute
    module ClassMixin
      def cache_attribute_values!(nodes,name)
        NodeAttribute.cache_attribute_values!(nodes,name)
      end

      # target_ref_attributes are ones used on target refs and can also be on instances
      def get_target_ref_attributes(node_idhs,opts={})
        cols = opts[:cols] || [:id,:display_name,:node_node_id,:attribute_value,:data_type]
        add_filter = NodeAttribute.target_ref_attributes_filter()
        get_node_level_attributes(node_idhs,cols: cols,add_filter: add_filter)
      end

      # node_level_assembly_template_attributes are ones that are persisted in service modules
      def get_node_level_assembly_template_attributes(node_idhs,opts={})
        cols = opts[:cols] || [:id,:display_name,:node_node_id,:attribute_value,:data_type]
        add_filter = NodeAttribute.assembly_template_attribute_filter()
        get_node_level_attributes(node_idhs,cols: cols,add_filter: add_filter)
      end

      def get_node_level_attributes(node_idhs,opts={})
        ret = []
        return ret if node_idhs.empty?()
        filter = [:oneof,:node_node_id,node_idhs.map{|idh|idh.get_id()}]
        if add_filter = opts[:add_filter]
          filter = [:and,filter,add_filter]
        end
        cols = opts[:cols] || [:id,:group_id,:display_name,:required]
        sp_hash = {
          cols: cols,
          filter: filter,
        }
        attr_mh = node_idhs.first.createMH(:attribute)
        opts = (cols.include?(:ref) ? {keep_ref_cols: true} : {})
        get_objs(attr_mh,sp_hash,opts)
      end

      def get_virtual_attributes(attrs_to_get,cols,field_to_match=:display_name)
        ret = {}
        # TODO: may be able to avoid this loop
        attrs_to_get.each do |node_id,hash_value|
          attr_info = hash_value[:attribute_info]
          node = hash_value[:node]
          attr_names = attr_info.map{|a|a[:attribute_name].to_s}
          rows = node.get_virtual_attributes(attr_names,cols,field_to_match)
          rows.each do |attr|
            attr_name = attr[field_to_match]
            ret[node_id] ||= {}
            ret[node_id][attr_name] = attr
          end
        end
        ret
      end

      # TODO: need tp fix up below; maybe able to deprecate
      def get_node_attribute_values(id_handle,opts={})
	c = id_handle[:c]
        node_obj = get_object(id_handle,opts)
        raise Error.new("node associated with (#{id_handle}) not found") if node_obj.nil?
	ret = node_obj.get_direct_attribute_values(:value) || {}

	cmps = node_obj.get_objects_associated_components()
	cmps.each do|cmp|
	  ret[:component]||= {}
	  cmp_ref = cmp.get_qualified_ref.to_sym
	  ret[:component][cmp_ref] =
	    cmp[:external_ref] ? {external_ref: cmp[:external_ref]} : {}
	  values = cmp.get_direct_attribute_values(:value,{attr_include: [:external_ref]})
	  ret[:component][cmp_ref][:attribute] = values if values
        end
        ret
      end
    end
  end
end; end
