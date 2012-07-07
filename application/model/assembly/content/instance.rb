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
        create(assembly_mh,hash_values)
      end
      def add_content_for_clone!(library_idh,node_idhs,port_links,augmented_lib_branches)
        node_scalar_cols = ContentObject::CommonCols + [:node_binding_rs_id]
        sample_node_idh = node_idhs.first
        node_mh = sample_node_idh.createMH()
        node_ids = node_idhs.map{|idh|idh.get_id()}

        #get contained ports
        sp_hash = {
          :cols => [:id,:display_name,:external_ports_for_clone],
          :filter => [:oneof,:id,node_ids]
        }
        @ndx_ports = Hash.new
        node_port_mapping = Hash.new
        Model.get_objs(node_mh,sp_hash,:keep_ref_cols => true).each do |r|
          port = r[:port]
          (node_port_mapping[r[:id]] ||= Array.new) << port
          @ndx_ports[port[:id]] = port
        end

        #get contained components-non-default attributes
        sp_hash = {
          :cols => node_scalar_cols + [:cmps_and_non_default_attrs],
          :filter => [:oneof,:id,node_ids]
        }

        node_cmp_attr_rows = Model.get_objs(node_mh,sp_hash,:keep_ref_cols => true)

        cmp_scalar_cols = node_cmp_attr_rows.first[:component].keys - [:non_default_attribute]
        @ndx_nodes = Hash.new
        node_cmp_attr_rows.each do | r|
          node_id = r[:id]
          @ndx_nodes[node_id] ||= r.hash_subset(*node_scalar_cols).merge(:components => Array.new,:ports => node_port_mapping[node_id])
          cmps = @ndx_nodes[node_id][:components]
          cmp_id = r[:component][:id]
          unless matching_cmp = cmps.find{|cmp|cmp[:id] == cmp_id}
            matching_cmp = r[:component].hash_subset(*cmp_scalar_cols).merge(:non_default_attributes => Array.new)
            cmps << matching_cmp
          end
          if attr = r[:non_default_attribute]
            matching_cmp[:non_default_attributes] << attr
          end
        end
        self[:nodes] = @ndx_nodes.values
        self[:port_links] = port_links
        @component_template_mapping = get_component_template_mapping(library_idh,augmented_lib_branches)
        self
      end
      def create_assembly_template(library_idh)
        nodes = self[:nodes].inject(Hash.new){|h,node|h.merge(create_node_content(node))}
        port_links = self[:port_links].inject(Hash.new){|h,pl|h.merge(create_port_link_content(pl))}

        template_output = TemplateOutput.new
        assembly_ref = self[:ref]
        #TODO: consider moving port link so it is conatined under assembly rather than being contained in library and points to assembly
        assembly_hash = Aux::hash_subset(self,[:display_name,:type,:ui,:module_branch_id])
        template_output.merge!(:node => nodes, :port_link => port_links, :component => {assembly_ref => assembly_hash})

        template_output.create(library_idh)
        template_output.serialize_and_save()
      end
     private
      #returns two key hash [cmp_type][ws_branch_id] -> cmp_template_id
      def get_component_template_mapping(library_idh,augmented_lib_branches)
        ret = Hash.new
        cmp_types = self[:nodes].map do |node|
          node[:components].map{|cmp|cmp[:component_type]}
        end.flatten
        branch_ids = augmented_lib_branches.map{|b|b[:id]}
        sp_hash = {
          :cols => [:id, :display_name,:module_branch_id,:component_type,:library_library_id],
          :filter => [:and,[:oneof, :component_type,cmp_types],[:oneof, :module_branch_id, branch_ids]]
        }
        lib_to_ws_branches = augmented_lib_branches.inject(Hash.new) do |h,r|
          h.merge(r[:id] => r[:workspace_module_branch][:id])
        end
        cmp_tmpls = Model.get_objs(library_idh.create_childMH(:component),sp_hash)
        cmp_tmpls.each do |cmp|
          lib_branch_id = cmp[:module_branch_id]
          (ret[cmp[:component_type]] ||= Hash.new).merge!(lib_to_ws_branches[lib_branch_id] => cmp[:id])
        end
        ret
      end

      def create_port_link_content(port_link)
        in_port = @ndx_ports[port_link[:input_id]]
        in_node_ref = node_ref(@ndx_nodes[in_port[:node_node_id]])
        in_port_ref = qualified_ref(in_port)
        out_port = @ndx_ports[port_link[:output_id]]
        out_node_ref = node_ref(@ndx_nodes[out_port[:node_node_id]])
        out_port_ref = qualified_ref(out_port)

        port_link_ref = "#{in_port_ref}-#{out_port_ref}"
        port_link_hash = {
          "*input_id" => "/node/#{in_node_ref}/port/#{in_port_ref}",
          "*output_id" => "/node/#{out_node_ref}/port/#{out_port_ref}",
          "*assembly_id" => "/component/#{self[:ref]}"
        }
        {port_link_ref => port_link_hash}
      end
      
      def node_ref(node)
        "#{self[:ref]}-#{node[:display_name]}"
      end
      def create_node_content(node)
        node_ref = node_ref(node)
        cmp_refs = node[:components].inject(Hash.new){|h,cmp|h.merge(create_component_ref_content(cmp))}
        ports = node[:ports].inject(Hash.new){|h,p|h.merge(create_port_content(p))}
        node_hash = Aux::hash_subset(node,[:display_name,:node_binding_rs_id])
        node_hash.merge!("*assembly_id" => "/component/#{self[:ref]}",:component_ref => cmp_refs, :port => ports)
        node_hash.merge!(:type => "stub")
        {node_ref => node_hash}
      end

      def create_port_content(port)
        port_ref = qualified_ref(port)
        port_hash = Aux::hash_subset(port,[:display_name,:description,:type,:direction])
        port_hash.merge!(:link_def_id => port[:link_def][:ancestor_id])
        {port_ref => port_hash}
      end

      def create_component_ref_content(cmp)
        cmp_ref_ref = qualified_ref(cmp)
        cmp_ref_hash = Aux::hash_subset(cmp,[:display_name,:description,:component_type])
        cmp_template_id = @component_template_mapping[cmp[:component_type]][cmp[:module_branch_id]]
        cmp_ref_hash.merge!(:component_template_id => cmp_template_id)
        unless cmp[:non_default_attributes].empty?
          raise Error.new("TODO: implement non default attttributes")
        end
        {cmp_ref_ref => cmp_ref_hash}
      end
      
      class TemplateOutput < Hash
        def create(library_idh)
          Model.import_objects_from_hash(library_idh,self)
        end
        def serialize_and_save()
        end
      end
    end
  end
end
