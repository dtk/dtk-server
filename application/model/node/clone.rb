module DTK; class Node
  module CloneMixin
    def add_model_specific_override_attrs!(override_attrs,target_obj)
      override_attrs[:type] ||= "staged"
      override_attrs[:ref] ||= SQL::ColRef.concat("s-",:ref)
      override_attrs[:display_name] ||= SQL::ColRef.concat{|o|["s-",:display_name,o.case{[[{:ref_num=> nil},""],o.concat("-",:ref_num)]}]}
    end

    def source_clone_info_opts()
      {:ret_new_obj_with_cols => [:id,:external_ref]}
    end

    def clone_pre_copy_hook(clone_source_object,opts={})
      if clone_source_object.model_handle[:model_name] == :component
        clone_source_object.clone_pre_copy_hook_into_node(self,opts)
      else
        clone_source_object
      end
    end

    def clone_post_copy_hook(clone_copy_output,opts={})
      component = clone_copy_output.objects.first
      ClonePostCopyHookComponent.new(self,component).process(opts)
    end

   private
    class ClonePostCopyHookComponent
      def initialize(node,component)
        @node = node
        @component = component
      end

      def process(opts={})
        relevant_nodes = [@node] 
        #if node is in assembly put component in the assembly
        if assembly_id = @node.get_field?(:assembly_id)
          @component.update(:assembly_id => assembly_id)
          assembly_idh = @node.id_handle(:model_name => :assembly,:id => assembly_id)
          relevant_nodes = Assembly::Instance.get_nodes([assembly_idh])
        end

        create_new_ports_and_links(relevant_nodes,opts)

        unless opts[:donot_create_pending_changes]
          parent_action_id_handle = @node.get_parent_id_handle()
          StateChange.create_pending_change_item(:new_item => @component.id_handle(), :parent => parent_action_id_handle)
        end
      end

     private
      def create_new_ports_and_links(relevant_nodes,opts={})
      
        #get the link defs/component_ports associated with components on the node or for assembly nodes on assembly; this is used
        #to determine if need to add internal links and for port processing
        node_link_defs_info = get_relevant_link_def_info(relevant_nodes)

        return if node_link_defs_info.empty?()

        new_ports = create_new_ports(node_link_defs_info,opts)

        #update node_link_defs_info with new ports
        unless new_ports.empty?()
#TODO:
Log.error("working on splicing in port ref to link def")
#          ndx_for_port_update = node_link_defs_info.inject(Hash.new){|h,ld|h.merge(ld[:id] => ld)}
 #         new_ports.each{|port| ndx_for_port_update[port[:link_def_id]].merge!(:port => port)}
        end

        if opts[:outermost_ports] 
          opts[:outermost_ports] += materialize_ports!(new_ports)
        end

        unless opts[:donot_create_internal_links]
          node_id = @node.id()
          internal_node_link_defs_info = node_link_defs_info.select{|r|r[:id] == node_id}
          unless internal_node_link_defs_info.empty?
            #TODO: AUTO-COMPLETE-LINKS: not sure if this is place to cal auto complete
            LinkDef::AutoComplete.create_internal_links(@node,@component,internal_node_link_defs_info)
          end
        end
      end

      def get_relevant_link_def_info(relevant_nodes)
        #TODO: creating rendundant info; probably just need to return the node info plus link def
        ret = Array.new
        sp_hash = {
          :cols => [:node_link_defs_info],
          :filter => [:oneof, :id, relevant_nodes.map{|n|n.id()}]
        }
        link_def_info_to_prune = Model.get_objs(@node.model_handle(),sp_hash)
        return ret if link_def_info_to_prune.empty?
          
        component_type = @component.get_field?(:component_type)
        component_id = @component.id()
        link_def_info_to_prune.each do |r|
          link_def = r[:link_def]
          if link_def[:component_component_id] == component_id
            ret << r.merge(:direction => :input)
          elsif r[:link_def_link] and (r[:link_def_link][:remote_component_type] == component_type)
            ret << r.merge(:direction => :output)
          end
        end
        ret
      end

      def create_new_ports(node_link_defs_info,opts={})
        ret = Array.new
        rows = node_link_defs.map do |r|
          link_def = r[:link_def]
          ret_port_create_hash(link_def,@node,@component,:direction => r[:direction])
        end
        create_opts = {:returning_sql_cols => [:link_def_id,:id,:display_name,:type,:connected]}
        port_mh = @node.model_handle(:port)
        create_from_rows(port_mh,rows,opts)
      end

      #TODO: may deprecate; used just for GUI
      def materialize_ports!(ports)
        ret = Array.new
        return ret if ports.empty?
        #TODO: more efficient way to do this; instead include all needed columns in :returning_sql_cols above
        port_mh = @node.model_handle(:port)
        external_port_idhs = ports.map do |port_hash|
          port_mh.createIDH(:id => port_hash[:id]) if ["component_internal_external","component_external"].include?(port_hash[:type])
        end.compact

        unless external_port_idhs.empty?
          new_ports = Model.get_objs_in_set(external_port_idhs, {:cols => Port.common_columns})
          i18n = @node.get_i18n_mappings_for_models(:component,:attribute)
          new_ports.map do |port|
            port.materialize!(Port.common_columns)
            port[:name] = get_i18n_port_name(i18n,port)
          end
        end
      end
    end
  end
end; end
