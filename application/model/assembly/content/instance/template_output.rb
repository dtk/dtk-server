module DTK
  class Assembly::Content::Instance
    class TemplateOutput < Hash
      include AssemblyImportExportCommon
      def initialize(container_idh,service_module_branch)
        super()
        @container_idh = container_idh
        @service_module_branch = service_module_branch
      end
      def save_to_model()
        Model.input_hash_content_into_model(@container_idh,self,:preserve_input_hash=>true)
      end
      def serialize_and_save_to_repo()
        hash_to_serialize = serialize()
        ordered_hash_content = SimpleOrderedHash.new([:node_bindings,:assemblies].map{|k|{k => hash_to_serialize[k]}})
        path = assembly_meta_filename_path()
        @service_module_branch.serialize_and_save_to_repo(path,ordered_hash_content)
        path
      end

      
      def synchronize_workspace_with_library_branch()
        lib_branch = @service_module_branch
        service_module = lib_branch.get_service_module()
        version=nil #TODO: stub
        if ws_branch = ModuleBranch.get_augmented_workspace_branch(service_module,version,:no_error_if_none=>true)
          repo = ws_branch[:workspace_repo]
          sync_result = repo.synchronize_workspace_with_library_branch(ws_branch,lib_branch)
          if sync_result == :merge_needed
            raise ErrorUsage.new("synchronize_workspace_with_library_branch needs merge")
          end
        end
      end
     private
      def assembly_meta_filename_path()
        ServiceModule::assembly_meta_filename_path(assembly_hash()[:display_name])
      end
      def serialize()
        assembly_hash = assembly_output_hash()
        node_bindings_hash = node_bindings_output_hash()
        ref = assembly_hash.delete(:ref)
        {:node_bindings => node_bindings_hash, :assemblies => {ref => assembly_hash}}
      end

      def assembly_output_hash()
        ret = SimpleOrderedHash.new()
        ret[:name] = assembly_hash()[:display_name]
        ret[:ref] = assembly_ref()
        #TODO: may put in version info
        #  "#{impl[:module_name]}-#{version}"
        #end

        #add assembly level attributes
        #TODO: stub
      
        #add nodes and components
        ret[:nodes] = self[:node].inject(SimpleOrderedHash.new()) do |h,(node_ref,node_hash)|
          node_name = node_hash[:display_name]
          cmp_info = node_hash[:component_ref].values.map{|cmp|component_output_form(cmp)}
          h.merge(node_name => {:components => cmp_info})
        end

        #add port links
        ret[:port_links] = self[:port_link].values.map do |pl|
           input_qual_port_ref = pl["*input_id"]
           output_qual_port_ref = pl["*output_id"]
           {port_output_form(input_qual_port_ref,:input) => port_output_form(output_qual_port_ref,:output)}
         end
        ret
      end

      def assembly_ref()
        self[:component].keys.first
      end
      def assembly_hash()
        self[:component].values.first
      end

      def node_bindings_output_hash()
        sp_hash = {
          :cols => [:id,:ref],
          :filter => [:oneof, :id, self[:node].values.map{|n|n[:node_binding_rs_id]}]
        }
        #TODO: may get this info in earlier phase
        node_binding_rows = Model.get_objs(@container_idh.createMH(:node_binding_ruleset),sp_hash,:keep_ref_cols => true)
        node_binding_id_to_ref = node_binding_rows.inject(Hash.new){|h,r|h.merge(r[:id] => r[:ref])}
        assembly_ref = assembly_ref()
        self[:node].inject(Hash.new) do |h,(node_ref,node_hash)|
          h.merge("#{assembly_ref}#{Seperators[:assembly_node]}#{node_hash[:display_name]}" => node_binding_id_to_ref[node_hash[:node_binding_rs_id]])
        end
      end

      def component_output_form(component_hash)
        name = component_name_output_form(component_hash[:component_type])
        if attr_overrides = component_hash[:attribute_override]
          {name => attr_overrides.values.inject(Hash.new){|h,a|h.merge(a[:display_name] => a[:attribute_value])}}
        else
          name 
        end
      end
      def component_name_output_form(internal_format)
        internal_format.gsub(/__/,Seperators[:module_component])
      end

      def port_output_form(qualified_port_ref,dir)
        #TODO: does this need fixing up in case a component can appear multiple times
        #TODO: assumption that port_ref == display_name
        port_ref = qualified_port_ref.split("/").last
        p = Port.parse_external_port_display_name(port_ref)
        node_ref = (qualified_port_ref =~ Regexp.new("^/node/([^/]+)");$1)
        unless matching_node = self[:node].find{|ref,hash|ref == node_ref}
          raise Error.new("Cannot find matching node for node ref #{node_ref})")
        end
        node_name = matching_node[1][:display_name]
        cmp_name = component_name_output_form(p[:component_type])
        sep = Seperators #just for succinctness
        "#{node_name}#{sep[:node_component]}#{cmp_name}#{sep[:component_port]}#{p[:link_def_ref]}"
      end
    end
  end
end
