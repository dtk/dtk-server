module DTK
  module TargetCloneMixin
    def clone_post_copy_hook(clone_copy_output,opts={})
      case clone_copy_output.model_name()
       when :component
        ClonePostCopyHook.component(self,clone_copy_output,opts)
       when :node
        ClonePostCopyHook.node(self,clone_copy_output,opts)
       else #TODO: catchall that will be expanded
        new_id_handle = clone_copy_output.id_handles.first
        StateChange.create_pending_change_item(:new_item => new_id_handle, :parent => id_handle())
      end
    end

    def create_state_changes_for_create_node?(node)
      ClonePostCopyHook.create_state_changes_for_create_node?(self,[node])
    end

   private
    module ClonePostCopyHook
      def self.node(target,clone_copy_output,opts)
        target.update_object!(:iaas_type,:iaas_properties)
        new_id_handle = clone_copy_output.id_handles.first
        #add external ref values from target to node if node does not have them
        #assuming passed already check whether node consistent requirements with target
        #TODO: not handling yet constraint form where set of possibilities given
        node = clone_copy_output.objects.first
        node_ext_ref = node[:external_ref]
        target[:iaas_properties].each do |k,v|
          unless node_ext_ref.has_key?(k)
            node_ext_ref[k] = v
          end
        end
        node.update(:external_ref => node_ext_ref)
        StateChange.create_pending_change_item(:new_item => new_id_handle, :parent => target.id_handle())
      end

      def self.component(target,clone_copy_output,opts)
        if assembly = clone_copy_output.assembly?(:subclass_object=>true)
          assembly(target,assembly,clone_copy_output,opts)
        else
          raise Error.new("Not implemented clone of non assembly component to target")
        end
      end

      def self.assembly(target,assembly,clone_copy_output,opts)
        #clone_copy_output will be of form: assembly - node - component

        #adjust link_def_id on ports
        set_ports_link_def_and_cmp_ids(clone_copy_output)

        #for port links that get generated by add on service
        #TODO: currently not used; may deprecate create_add_on_port_and_attr_links?(target,clone_copy_output,opts)

        level = 1
        nodes = clone_copy_output.children_objects(level,:node,:cols=>[:display_name,:external_ref,:type])
        return if nodes.empty?
        SpecialNodeAttributes.process!(nodes)

        # The method create_target_refs_and_links?
        # - creates if needed target refs and links to them
        # - moves node attributes to the target refs
        # - returns any neededed 'create node' state change objects, which designate that
        #   target ref node needs to be created as opposed to it exists already
        tr_state_changes = Node::TargetRef::Clone.new(target,assembly,nodes).create_target_refs_and_links?()
        create_state_changes_for_create_node?(target,tr_state_changes)

        # Computing port_links (and also attribute links after create_target_refs_and_links
        # because relying on the node attributes to be shifted to target refs if connected to target refs
        port_link_idhs = clone_copy_output.children_id_handles(level,:port_link)
        assembly__port_links(target,clone_copy_output,port_link_idhs,opts)

        level = 2
        component_child_hashes = clone_copy_output.children_hash_form(level,:component)
        return if component_child_hashes.empty?
        component_new_items = component_child_hashes.map do |child_hash|
          {:new_item => child_hash[:id_handle], :parent => target.id_handle()}
        end

        if settings = opts[:service_settings]
          settings.apply_settings(target,assembly)
        end

        StateChange.create_pending_change_items(component_new_items)
      end

      module SpecialNodeAttributes
        def self.process!(nodes)
          process_name_attribute!(nodes)
          process_cardinality_attribute!(nodes)
        end
       private
        def self.process_name_attribute!(nodes)
          constant_attr_fields = {:hidden => true}
          nodes.each do |n| 
            name = n.get_field?(:display_name)
            Node::NodeAttribute.create_or_set_attributes?([n],:name,name,constant_attr_fields)
          end
        end

        def self.process_cardinality_attribute!(nodes)
          # first set cardinality on node groups
          ndx_cardinality = Hash.new
          nodes.each do |n|
            if n.is_node_group?()
              if card =  n[:target_refs_to_link] && n[:target_refs_to_link].size
                (ndx_cardinality[card] ||= Array.new) << n
              end
            end
          end
          ndx_cardinality.each_pair do |card,nodes_to_set_card|
            Node::NodeAttribute.create_or_set_attributes?(nodes_to_set_card,:cardinality,card)
          end
          Node.cache_attribute_values!(nodes,:cardinality)
        end
      end

      def self.create_state_changes_for_create_node?(target,nodes)
        #Do not create stages for node that are physical
        pruned_nodes = nodes.reject do |node|
          (node.get_field?(:external_ref)||{})[:type] == 'physical'
        end
        return if pruned_nodes.empty?

        target_idh = target.id_handle()
        node_new_items = pruned_nodes.map{|node|{:new_item => node.id_handle(), :parent => target_idh}}
        sc_hashes = create_state_change_objects(target_idh,node_new_items)
        create_state_changes_for_node_group_members(target_idh,pruned_nodes,sc_hashes)
        nil
      end

      def self.create_state_changes_for_node_group_members(target_idh,nodes,sc_hashes)
        ret = Array.new
        node_groups = nodes.select{|n|n.is_node_group?()}
        return ret if node_groups.empty?
        ng_mh =  node_groups.first.model_handle()
        ndx_sc_ids = sc_hashes.inject(Hash.new){|h,sc|h.merge(sc[:node_id] => sc[:id])}
        sc_mh = target_idh.createMH(:state_change)
        new_items_hash = Array.new
        ServiceNodeGroup.get_ndx_node_members(node_groups.map{|ng|ng.id_handle()}).each do |ng_id,node_members|
          unless ng_state_change_id = ndx_sc_ids[ng_id]
            Log.eror("Unexpected that ndx_sc_ihs[ng_id] is null")
            next
          end
          ng_state_change_idh = sc_mh.createIDH(:id => ng_state_change_id)
          node_members.each do |node|
            new_items_hash << {:new_item => node.id_handle(), :parent => ng_state_change_idh}
          end
        end
        create_state_change_objects(target_idh,new_items_hash)
      end

      def self.create_state_change_objects(target_idh,new_items_hash)
        opts_sc = {:target_idh => target_idh,:returning_sql_cols => [:id,:display_name,:group_id,:node_id]}
        StateChange.create_pending_change_items(new_items_hash,opts_sc)
      end

      def self.create_add_on_port_and_attr_links?(target,clone_copy_output,opts)
        sao_proc = opts[:service_add_on_proc]
        pl_hashes = sao_proc && sao_proc.get_matching_ports_link_hashes_in_target(clone_copy_output.id_handles.first)
        unless pl_hashes.nil? or pl_hashes.empty?
          # TODO: more efficient if had bulk create; also may consider better intergrating with creation of the assembly proper's port links
          target_idh = target.id_handle()
          pl_hashes.each do |port_link_hash|
            PortLink.create_port_and_attr_links(target_idh,port_link_hash,opts)
          end
        end
      end

      def self.set_ports_link_def_and_cmp_ids(clone_copy_output)
        ports = clone_copy_output.children_hash_form(2,:port).map{|r|r[:obj_info]}
        return if ports.empty?
        port_mh = clone_copy_output.children_id_handles(2,:port).first.createMH()
        cmps = clone_copy_output.children_hash_form(2,:component).map{|r|r[:obj_info]}
        link_defs = clone_copy_output.children_hash_form(3,:link_def).map{|r|r[:obj_info]}
        Port.set_ports_link_def_and_cmp_ids(port_mh,ports,cmps,link_defs)
      end

      def self.assembly__port_links(target,clone_copy_output,port_link_idhs,opts)
        #find the port_links under the assembly and then add attribute_links associated with it
        #  TODO: this may be considered bug; but at this point assembly_id on port_links point to assembly library instance
        return if port_link_idhs.empty?
        sample_pl_idh = port_link_idhs.first
        port_link_mh =  sample_pl_idh.createMH()
        sp_hash = {
          :cols => [:id,:display_name,:group_id,:input_id,:output_id],
          :filter => [:oneof,:id, port_link_idhs.map{|pl_idh|pl_idh.get_id()}]
        }
        Model.get_objs(port_link_mh,sp_hash).each do |port_link|
          port_link.create_attr_links!(target.id_handle,:set_port_link_temporal_order=>true)
        end
      end
    end
  end
end
