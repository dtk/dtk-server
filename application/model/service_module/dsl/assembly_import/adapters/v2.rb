module DTK; class ServiceModule
  class AssemblyImport
    class V2 < self
      def self.assembly_iterate(module_name,hash_content,&block)
        name = hash_content["name"]
        assemblies_hash = {ServiceModule.assembly_ref(module_name,name) => hash_content["assembly"].merge("name" => name)}
        node_bindings_hash = hash_content["node_bindings"]
        block.call(assemblies_hash,node_bindings_hash)
      end

      def self.import_port_links(assembly_idh,assembly_ref,assembly_hash,ports)
        #augment ports with parsed display_name
        augment_with_parsed_port_names!(ports)
        port_links = parse_service_links(assembly_hash).inject(DBUpdateHash.new) do |h,parsed_service_link|
          input = parsed_service_link[:input]
          output = parsed_service_link[:output]
          input_id = input.matching_id(ports)
          #only need to test output because this is embedded within input
          unless output_id = output.matching_id(ports,:do_not_throw_error => true)
            raise ErrorUsage.new("The service link reference (#{pp_port_ref(output)}) does not match")
          end
          pl_ref = PortLink.ref_from_ids(input_id,output_id)
          pl_hash = {"input_id" => input_id,"output_id" => output_id, "assembly_id" => assembly_idh.get_id()}
          h.merge(pl_ref => pl_hash)
        end
        port_links.mark_as_complete(:assembly_id=>@existing_assembly_ids)
        {assembly_ref => {"port_link" => port_links}}
      end

     private
      include AssemblyImportExportCommon

      def self.pp_port_ref(port_ref)
        ret = "#{port_ref[:node]}/#{port_ref[:component_type].gsub(/__/,"::")}"
        if title = port_ref[:title]
          ret << "[#{title}]"
        end
        ret
      end

      #pattern that appears in dsl that designates a component title
      DSLComponentTitleRegex = /(^.+)\[(.+)\]/
      
      def self.component_ref_parse(cmp)
        term = (cmp.kind_of?(Hash) ?  cmp.keys.first : cmp).gsub(Regexp.new(Seperators[:module_component]),"__")
        ref = term
        display_name = term
        if term =~ Regexp.new("(^.+)#{Seperators[:component_version]}(.+$)")
          type = $1; version = $2
        else
          type = term; version = nil
        end

        component_title = nil
        if type =~ DSLComponentTitleRegex
          type = $1
          component_title = $2
          ref = ComponentTitle.ref_with_title(type,component_title)
          display_name = ComponentTitle.display_name_with_title(type,component_title)
        end

        ret = {:component_type => type, :ref => ref, :display_name => display_name}
        ret.merge!(:version => version) if version
        ret.merge!(:component_title => component_title) if component_title
        ret
      end

      def self.parse_service_links(assembly_hash)
        ret = Array.new
        assembly_hash["nodes"].each_pair do |input_node_name,node_hash|
          (node_hash["components"]||[]).each do |input_cmp|
            if input_cmp.kind_of?(Hash) 
              input_cmp_name = input_cmp.keys.first
              (input_cmp.values.first["service_links"]||{}).each_pair do |link_def_type,target|
                ret << AssemblyImportPortRef.parse_service_link(input_node_name,input_cmp_name,link_def_type => target)
              end
            end
          end
        end
        ret
      end

      def self.ret_node_to_node_binding_rs(assembly_ref,node_bindings_hash)
        (node_bindings_hash||{}).inject(Hash.new) do |h,(node,v)|
          merge_hash = 
            if v.kind_of?(String) then {node => v}
            elsif v.kind_of?(Hash)
              Log.error("Not implemented yet have node bindings with explicit properties")
              Hash.new
            else
              raise Error.new("Unexpected form of node binding")
            end
          h.merge(merge_hash)
        end
      end

      def self.ret_attribute_overrides(cmp_input)
        (cmp_input.kind_of?(Hash) && cmp_input.values.first["attributes"])||{}
      end
      
    end
  end
end; end
