module XYZ
  module TargetCloneMixin
    def clone_post_copy_hook(clone_copy_output,opts={})
      case clone_copy_output.model_name()
       when :component 
        ClonePostCopyHook.component(self,clone_copy_output,opts)
       when :node
        ClonePostCopyHook.node(self,clone_copy_output,opts)        
       else #TODO: catchall taht will be expanded
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
        if clone_copy_output.is_assembly?()
          assembly(target,clone_copy_output,opts)
        else
          raise Error.new("Not implemented clone of non assembly component to target")
        end
      end

      def self.assembly(target,clone_copy_output,opts)
        #clone_copy_output will be of form: assembly - node - component

        #adjust link_def_id on ports
        #TODO: betetr if did this by default in fk - key_shift
        set_ports_link_def_ids(clone_copy_output)

        level = 1
        port_link_idhs = clone_copy_output.children_id_handles(level,:port_link)
        assembly__port_links(target,clone_copy_output,port_link_idhs,opts)
        
        node_idhs = clone_copy_output.children_id_handles(level,:node)
        node_new_items = node_idhs.map{|idh|{:new_item => idh, :parent => target.id_handle()}}
        return if node_new_items.empty?
        node_sc_idhs = StateChange.create_pending_change_items(node_new_items)
        
        indexed_node_info = Hash.new #TODO: may have state create this as output
        node_sc_idhs.each_with_index{|sc_idh,i|indexed_node_info[node_idhs[i].get_id()] = sc_idh}


        level = 2
        component_child_hashes =  clone_copy_output.children_hash_form(level,:component)
        project = target.get_project()
        #TODO: more efficient to do in bulk
        component_child_hashes.each do |child_hash|
          cmp = child_hash[:id_handle].create_object()
          #creates implementation adn module branches and updates component to point to these
          cmp.create_component_module_workspace?(project)
        end
        component_new_items = component_child_hashes.map do |child_hash| 
          {:new_item => child_hash[:id_handle], :parent => target.id_handle()}
        end
        return if component_new_items.empty?
        StateChange.create_pending_change_items(component_new_items)
      end

      def self.set_ports_link_def_ids(clone_copy_output)
        ports = clone_copy_output.children_hash_form(2,:port).map{|r|r[:obj_info]}
        return if ports.empty?
        cmps = clone_copy_output.children_hash_form(2,:component).map{|r|r[:obj_info]}
        link_defs = clone_copy_output.children_hash_form(3,:link_def).map{|r|r[:obj_info]}
        update_rows = ports.map do |port|
          cmp_type = Port.parse_external_port_display_name(port[:display_name])[:component_type]
          node_node_id = port[:node_node_id]
          #TODO: check display name will always be same as component_type
          cmp_match = cmps.find{|cmp|cmp[:display_name] == cmp_type and cmp[:node_node_id] == node_node_id}
          unless cmp_match
            Log.error("Cannot find matching component for cloned port with id (#{port[:id].to_s})")
            next
          end
          cmp_id = cmp_match[:id]
          link_def_match = link_defs.find{|ld|ld[:component_component_id] ==  cmp_id}
          unless link_def_match
            Log.error("Cannot find matching link def for component with id (#{cmp_id})")
            next
          end
          {:id => port[:id], :link_def_id => link_def_match[:id]}
        end.compact
        port_mh = clone_copy_output.children_id_handles(2,:port).first.createMH()
        Model.update_from_rows(port_mh,update_rows)
      end

      def self.assembly__port_links(target,clone_copy_output,port_link_idhs,opts)
        #find the port_links under the assembly and then add attribute_links associated with it
        #  TODO: this may be considered bug; but at this point assembly_id on port_links point to assembly library instance
        return if port_link_idhs.empty?
        sample_pl_idh = port_link_idhs.first
        port_link_mh =  sample_pl_idh.createMH()
        sp_hash = {
          :cols => [:id,:input_id,:output_id],
          :filter => [:oneof, :id, port_link_idhs.map{|pl_idh|pl_idh.get_id()}]
        }
        Model.get_objs(port_link_mh,sp_hash).each do |port_link|
          port_link.create_attr_links(target.id_handle)
        end
      end
    end
  end
end
