module DTK
  class Assembly::Instance
    class TemplateOutput < Hash
      include AssemblyImportExportCommon
      def create(library_idh)
        Model.input_hash_content_into_model(library_idh,self,:preserve_input_hash=>true)
      end
      def serialize_and_save_to_repo(service_module_branch)
        serialized_hash = serialize()
return
        content = JSON.pretty_generate(SimpleOrderedHash.new([:node_bindings,:assemblies].map{|k|{k => serialized_hash[k]}}) )
        filename = assembly_meta_filename()
        RepoManager.add_file({:path => filename},content,module_branch)
        filename
      end
     private
      def assembly_meta_filename()
        "#{self[:display_name]}.assembly.json"
      end
      def serialize()
        assembly_hash = assembly_output_hash()
pp assembly_hash
return
        node_bindings_hash = node_bindings_output_hash()
        ref = assembly_hash.delete(:ref)
        {:node_bindings => node_bindings_hash, :assemblies => {ref => assembly_hash}}
      end

      def assembly_output_hash()
        ret = SimpleOrderedHash.new()
        assembly_ref = self[:component].keys.first
        assembly_hash = self[:component].values.first 
        ret[:name] = assembly_hash[:display_name]
        ret[:ref] = assembly_ref
        #TODO
        #add modules
        #ret[:modules] = nested_objs[:implementations].map do |impl|
        #  version = impl[:version]
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

      def component_output_form(component_hash)
        name = component_name_output_form(component_hash[:component_type])
        if component_hash[:attributes]
          {name => component_hash[:attributes].inject(Hash.new){|h,a|h.merge(a[:display_name] => a[:attribute_value])}}
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
        #TODO: think need the node info (which is in qualified_port_ref)
        "#{p[:module]}#{Seperators[:module_component]}#{p[:component]}#{Seperators[:component_port]}#{p[:link_def_ref]}"
      end
    end
  end
end
