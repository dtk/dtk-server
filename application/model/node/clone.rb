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
      ClonePostCopyHook.new(self).process_component(component,opts)
    end

   private
    class ClonePostCopyHook
      def initialize(node)
        @node = node
      end
      def process_component(component,opts={})
        #if node is in assembly put component in the assembly
        if assembly_id = @node.get_field?(:assembly_id)
          component.update(:assembly_id => assembly_id)
        end

        #get the link defs/component_ports associated with components on the node; this is used
        #to determine if need to add internal links and for port processing
        node_link_defs_info = @node.get_objs(:cols => [:node_link_defs_info])

        new_ports = create_new_ports(component,node_link_defs_info,opts)

        #update node_link_defs_info with new ports
        unless new_ports.empty?()
          ndx_for_port_update = node_link_defs_info.inject(Hash.new){|h,r|h.merge(link_def[:id] => r)}
          new_ports.each{|port| ndx_for_port_update[port[:link_def_id]].merge!(:port => port)}
        end

        if opts[:outermost_ports] 
          opts[:outermost_ports] += materialize_ports!(new_ports)
        end

        unless opts[:donot_create_internal_links]
          LinkDef.create_needed_internal_links(@node,component,node_link_defs_info)
        end

        unless opts[:donot_create_pending_changes]
          parent_action_id_handle = @node.get_parent_id_handle()
          StateChange.create_pending_change_item(:new_item => component.id_handle(), :parent => parent_action_id_handle)
        end
      end

     private
      def create_new_ports(component,node_link_defs_info,opts={})
        ret = Array.new
        component_id = component.id()
        component_link_defs = node_link_defs_info.map  do |r|
          link_def = r[:link_def]
          if link_def[:component_component_id] == component_id
            link_def 
          end
        end.compact

        create_opts = {:returning_sql_cols => [:link_def_id,:id,:display_name,:type,:connected]}
        Port.create_component_ports?(component_link_defs,@node,component,create_opts)
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
