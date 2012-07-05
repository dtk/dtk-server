module DTK
  class Assembly
    class Instance < Content
      def self.create_container_for_clone(library_idh,assembly_name,service_module_name,service_module_branch,icon_info)
        hash_values = {
          :library_library_id => library_idh.get_id(),
          :ref => "#{service_module_name}-#{assembly_name}",
          :display_name => assembly_name,
          :ui => icon_info,
          :type => "composite",
          :module_branch_id => service_module_branch[:id]
        }
        assembly_mh = library_idh.create_childMH(:component)
        ret = create(assembly_mh,hash_values)
        pp [ret.class,ret.id_handle,ret]
        ret
      end
      def add_content_for_clone!(node_idhs,link_idhs)
        node_scalar_cols = ContentObject::CommonCols + [:node_binding_rs_id]
        sp_hash = {
          :cols => node_scalar_cols + [:cmps_and_non_default_attrs],
          :filter => [:oneof,:id,node_idhs.map{|idh|idh.get_id()}]
        }
        sample_node_idh = node_idhs.first
        node_mh = sample_node_idh.createMH()
        content_rows = Model.get_objs(node_mh,sp_hash,:keep_ref_cols => true)
        cmp_scalar_cols = content_rows.first[:component].keys - [:non_default_attribute]
        ndx_nodes = Hash.new
        content_rows.each do | r|
          node_id = r[:id]
          cmps = (ndx_nodes[node_id] ||= Aux.hash_subset(r,node_scalar_cols).merge(:components => Array.new))[:components]
          cmp_id = r[:component][:id]
          unless matching_cmp = cmps.find{|cmp|cmp[:id] == cmp_id}
            matching_cmp = Aux.hash_subset(r[:component],cmp_scalar_cols).merge(:non_default_attributes => Array.new)
            cmps << matching_cmp
          end
          if attr = r[:non_default_attribute]
            matching_cmp[:non_default_attributes] << attr
          end
        end
        self[:nodes] = ndx_nodes.values
pp self
        self
      end
      def create_assembly_template(library_idh,augmented_lib_branches)
      end
    end
  end
end
