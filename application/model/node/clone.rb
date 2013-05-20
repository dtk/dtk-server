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
        @relevant_node_ids = get_relevant_node_ids(node,component)
      end

      def process(opts={})
        create_new_ports_and_links(opts)

        unless opts[:donot_create_pending_changes]
          parent_action_id_handle = @node.get_parent_id_handle()
          StateChange.create_pending_change_item(:new_item => @component.id_handle(), :parent => parent_action_id_handle)
        end
      end

     private
      def get_relevant_node_ids(node,component)
        if assembly_id = node.get_field?(:assembly_id)
          component.update(:assembly_id => assembly_id)
          assembly_idh = @node.id_handle(:model_name => :assembly,:id => assembly_id)
          Assembly::Instance.get_nodes([assembly_idh]).map{|n|n.id}
        else
          [node.id()]
        end
      end

      def create_new_ports_and_links(opts={})
        #get the link defs/component_ports associated with components on the node or for assembly, associated with an assembly node
        node_link_defs_info = get_relevant_link_def_info()

        return if node_link_defs_info.empty?()

        new_ports = create_new_ports(node_link_defs_info,opts)

        unless opts[:donot_create_internal_links]
          #set internal_node_link_defs_info and add any with new ports
          internal_node_link_defs_info = Array.new
          node_id = @node.id()
          node_link_defs_info.each do |r|
            if r[:id] == node_id
              link_def_id = r[:link_def_id]
              r[:port] ||= new_ports.find{|port|port[:link_def_id] = link_def_id}
            end
          end
          unless internal_node_link_defs_info.empty?
            #TODO: AUTO-COMPLETE-LINKS: not sure if this is place to cal auto complete
            LinkDef::AutoComplete.create_internal_links(@node,@component,internal_node_link_defs_info)
          end
        end

        if opts[:outermost_ports] 
          opts[:outermost_ports] += materialize_ports!(new_ports)
        end
      end

      def get_relevant_link_def_info()
        ret = Array.new
        sp_hash = {
          :cols => [:node_link_defs_info],
          :filter => [:oneof, :id, @relevant_node_ids]
        }
        link_def_info_to_prune = Model.get_objs(@node.model_handle(),sp_hash)
        return ret if link_def_info_to_prune.empty?
          
        component_type = @component.get_field?(:component_type)
        component_id = @component.id()
        ndx_ret = Hash.new
        link_def_info_to_prune.each do |r|
          link_def = r[:link_def]
          ndx = link_def[:id]
          unless ndx_ret[ndx]
            if link_def[:component_component_id] == component_id
              ndx_ret[ndx] = r.merge(:direction => "input")
            elsif (r[:link_def_link]||{})[:remote_component_type] == component_type
              ndx_ret[ndx] = r.merge(:direction => "output")
            end
          end
        end
        ndx_ret.values()
      end

      #This creates either ports on @component or ports connected by link def to @component
      def create_new_ports(node_link_defs_info,opts={})
        ret = Array.new
        #find info about any component/ports belonging to a relevant node of that is connected by link def to @component
        cmps = get_relevant_components(node_link_defs_info)
        ports = get_relevant_ports(cmps)

        rows = node_link_defs_info.map do |r|
          link_def = r[:link_def]
          Port.ret_port_create_hash(link_def,@node,@component,:direction => r[:direction])
        end
        create_opts = {:returning_sql_cols => [:link_def_id,:id,:display_name,:type,:connected]}
        port_mh = @node.model_handle(:port)
        Model.create_from_rows(port_mh,rows,opts)
      end

      def get_relevant_components(node_link_defs_info)
        ret = Array.new
        ndx_remote_cmp_types = Hash.new
        node_link_defs_info.each do |r|
          if r[:direction] == "input"
            cmp_type = r[:link_def_link][:remote_component_type]
            ndx_remote_cmp_types[cmp_type] ||= true
          end
        end
        return ret if ndx_remote_cmp_types.empty?()
        
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:component_type],
          :filter => [:and, [:oneof, :node_node_id, @relevant_node_ids],
                      [:oneof,:component_type,ndx_remote_cmp_types.keys()]]
        }
        cmp_mh = @node.model_handle(:component)
        Model.get_objs(cmp_mh,sp_hash)
      end
      
      def get_relevant_ports(cmps)
        ret = Array.new
        sp_hash = {
          :cols => [:id,:group_id,:display_name],
          :filter => [:oneof, :node_node_id, @relevant_node_ids]
        }
        port_mh = @node.model_handle(:port)
        ports = Model.get_objs(port_mh,sp_hash)
        return ret if ports.empty?
        ports.each{|port|port.set_port_info!()}
        cmp_types = cmps.map{|cmp|cmp[:component_type]}
        ports.select{|port|cmp_types.include?(port[:port_info][:component_type])}
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
