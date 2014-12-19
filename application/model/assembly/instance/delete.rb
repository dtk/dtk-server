module DTK; class  Assembly
  class Instance
    module DeleteClassMixin
      def delete(assembly_idhs,opts={})
        if assembly_idhs.kind_of?(Array)
          return if assembly_idhs.empty?
        else
          assembly_idhs = [assembly_idhs]
        end
        # cannot delete workspaces
        if workspace = assembly_idhs.find{|idh|Workspace.is_workspace?(idh.create_object())}
          raise ErrorUsage.new("Cannot delete a workspace")
        end
        Delete.contents(assembly_idhs,opts)
        delete_instances(assembly_idhs)
      end

      def delete_contents(assembly_idhs,opts={})
        Delete.contents(assembly_idhs,opts)
      end
    end

    module DeleteMixin
      def destroy_and_reset_nodes()
        nodes = Delete.get_nodes_simple(model_handle(:node),[id()])
# TODO: DTK-1857
if nodes.find{|n|n.is_node_group?()}
  raise ErrorUsage.new("destroy_and_reset_nodes not supported for service instances with node groups")
end
        target_idh = get_target.id_handle()
        nodes.map{|node|node.destroy_and_reset(target_idh)}
      end
      
      def delete_node(node_idh,opts={})
        node =  node_idh.create_object()
        # TODO: check if cleaning up dangling links when assembly node deleted
        Delete.node(node,opts.merge(:update_task_template=>true,:assembly=>self))
      end
      
      def delete_component(component_idh, node_id=nil)
        component_filter = [:and, [:eq, :id, component_idh.get_id()], [:eq, :assembly_id, id()]]
        node = nil
        # first check that node belongs to this assebmly
        unless !node_id.nil? && node_id.empty?
          sp_hash = {
            :cols => [:id, :display_name,:group_id],
            :filter => [:and, [:eq, :id, node_id], [:eq, :assembly_id, id()]]
          }
          
          unless node = Model.get_obj(model_handle(:node),sp_hash)
            raise ErrorIdInvalid.new(node_id,:node)
          end
          component_filter << [:eq, :node_node_id, node_id]
        end
        
        # also check that component_idh belongs to this instance and to this node
        sp_hash = {
        #:only_one_per_node,:ref are put in for info needed when getting title
          :cols => [:id, :display_name, :node_node_id,:only_one_per_node,:ref],
          :filter => component_filter
        }
        component = Component::Instance.get_obj(model_handle(:component),sp_hash)
        unless component
          raise ErrorIdInvalid.new(component_idh.get_id(),:component)
        end
        node ||= component_idh.createIDH(:model_name => :node,:id => component[:node_node_id]).create_object()
        ret = nil
        Transaction do
          node.update_dangling_links(:component_idhs => [component.id_handle()])
          Task::Template::ConfigComponents.update_when_deleted_component?(self,node,component)
          ret = Model.delete_instance(component_idh)
        end
        ret
      end
    end

    class Delete < self
      def Delete.contents(assembly_idhs,opts={})
        return if assembly_idhs.empty?
        delete(get_sub_assemblies(assembly_idhs).map{|r|r.id_handle()})
        assembly_ids = assembly_idhs.map{|idh|idh.get_id()}
        idh = assembly_idhs.first
        Delete.assembly_modules?(assembly_idhs,opts)
        # Delete.assembly_modules? needs to be done before Delete.assembly_nodes
        Delete.assembly_nodes(idh.createMH(:node),assembly_ids,opts)
        Delete.task_templates(idh.createMH(:task_template),assembly_ids)
      end

      def self.get_nodes_simple(node_mh,assembly_ids)
        assembly_idhs = assembly_ids.map{|id|node_mh.createIDH(:id => id,:model_name => :assembly_instance)}
        Assembly::Instance.get_nodes_simple(assembly_idhs,:ret_subclasses=>true)
      end

     private
      def Delete.task_templates(task_template_mh,assembly_ids)
        sp_hash = {
          :cols => [:id,:display_name],
          :filter => [:oneof,:component_component_id,assembly_ids] 
        }
        delete_instances(get_objs(task_template_mh,sp_hash).map{|tt|tt.id_handle()})
      end

      def Delete.assembly_modules?(assembly_idhs,opts={})
        assembly_idhs.each do |assembly_idh|
          assembly = create_from_id_handle(assembly_idh)
          AssemblyModule.delete_modules?(assembly,opts)
        end
      end

      # This only deletes the nodes that the assembly 'owns'; with sub-assemblies, the assembly base will own the node
      def Delete.assembly_nodes(node_mh,assembly_ids,opts={})
        Delete.nodes(node_mh,assembly_ids,opts)
      end

      def Delete.nodes(node_mh,assembly_ids,opts={})
        nodes = get_nodes_simple(node_mh,assembly_ids)
        nodes.map{|node|Delete.node(node,opts)}
      end

      # TODO: double check if Transaction needed; if so look at whether for same reason put in destoy and reset
      def Delete.node(node,opts={})
        ret = nil
        Transaction do 
          ret = 
            if opts[:destroy_nodes]
              node.destroy_and_delete(opts)
            else
              node.delete_object(opts)
            end
        end
        ret
      end
    end
  end
end; end
