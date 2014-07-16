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

        #for port links taht get generated by add on service
        #TODO: currently not used; may deprecate create_add_on_port_and_attr_links?(target,clone_copy_output,opts)

        level = 1
        port_link_idhs = clone_copy_output.children_id_handles(level,:port_link)
        assembly__port_links(target,clone_copy_output,port_link_idhs,opts)

        nodes = clone_copy_output.children_objects(level,:node, :cols=>[:display_name,:external_ref,:type])
        return if nodes.empty?

        Node.cache_attribute_values!(nodes,:cardinality)

        #This creates if needed target refs and links to them
        create_target_refs_and_links?(target,assembly,nodes)
        level = 2

        component_child_hashes = clone_copy_output.children_hash_form(level,:component)
        return if component_child_hashes.empty?
        component_new_items = component_child_hashes.map do |child_hash|
          {:new_item => child_hash[:id_handle], :parent => target.id_handle()}
        end
        StateChange.create_pending_change_items(component_new_items)
      end

      # this creates needed target refs and their links to them
      # there are a number of cases treated on a node by node basis (i.e., member of nodes)
      #  if node is a group then creating new target refs for it as function of its cardinality
      #  if node has been designated as matched to an existing target ref, need to create links to these
      #  otherwise create a state change object
      def self.create_target_refs_and_links?(target,assembly,nodes)
        tr_create = Array.new
        tr_link = Hash.new
        ndx_needs_sc = Hash.new

        partition = [tr_create,Array.new]
        nodes.each{|node|partition[node.is_node_group?() ? 0 : 1] << node}

        # partition[1] are non node groups; elements we want to see if point to a node_template that is a target ref
        unless partition[1].empty?
          #initiallly set ndx_needs_state_change to true
          ndx_needs_sc = partition[1].inject(Hash.new){|h,n|h.merge(n[:id] => n)}

          ndx_node_template__node = partition[1].inject(Hash.new) do |h,n|
            n[:node_template_id] ? h.merge!(n[:node_template_id] => n[:id]) : h
          end
          unless ndx_node_template__node.empty?
            sp_hash = {
              :cols => [:id,:display_name,:type],
              :filter => [:oneof,:id,ndx_node_template__node.keys]
            }
            Model.get_objs(target.model_handle(:node),sp_hash).each do |nt|
              if nt[:type] == Node::TargetRef.type()
                node_id = nt[:id]
                tr_link.merge!(ndx_node_template__node[node_id] => nt)
                ndx_needs_sc[node_id] = nil
              end
            end
          end 
        end

        unless tr_link.empty? and tr_create.empty?
          annotated_nodes = Node::TargetRef::AnnotatedNodes.new(tr_link,tr_create)
          opts_target_ref = {:do_not_check_link_exists => true} #know that link does not exist since new node instances
          Node::TargetRef.create_target_refs_and_links?(target,assembly,annotated_nodes,opts_target_ref)
        end

        needs_state_change = ndx_needs_sc.reject{|node,needs_sc|!needs_sc}.values
        create_state_changes_for_create_node?(target,needs_state_change)
      end

      def self.create_state_changes_for_create_node?(target,nodes)
        #Do not create stages for node that are physical
        pruned_nodes = nodes.reject do |node|
          (node.get_field?(:external_ref)||{})[:type] == 'physical'
        end
        return if pruned_nodes.empty?

        target_idh = target.id_handle()
        node_new_items = pruned_nodes.map{|node|{:new_item => node.id_handle(), :parent => target_idh}}
        StateChange.create_pending_change_items(node_new_items)
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
