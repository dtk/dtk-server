module DTK; class ServiceModule
  class AssemblyImport
    class V2 < self
      def self.assembly_iterate(module_name,hash_content,&block)
        assembly_hash = hash_content["assembly"].merge(Aux::hash_subset(hash_content,["name","workflow"]))
        assembly_ref = ServiceModule.assembly_ref(module_name,hash_content["name"])
        assemblies_hash = {assembly_ref => assembly_hash}
        node_bindings_hash = hash_content["node_bindings"]
        block.call(assemblies_hash,node_bindings_hash)
      end

      def self.import_assembly_top(serialized_assembly_ref,assembly_hash,module_branch,module_name)
        ret = super
        if task_templates = import_task_templates(assembly_hash)
          ret_assembly_hash = ret.values.first
          ret_assembly_hash.merge!("task_template" => task_templates)
        end
        ret
      end

      def self.import_port_links(assembly_idh,assembly_ref,assembly_hash,ports)
        #augment ports with parsed display_name
        augment_with_parsed_port_names!(ports)
        port_links = parse_service_links(assembly_hash).inject(DBUpdateHash.new) do |h,parsed_service_link|
          input = parsed_service_link[:input]
          output = parsed_service_link[:output]
          
          input_id = input.matching_id(ports,:do_not_throw_error => true)
          return input_id if input_id.is_a?(ErrorUsage::DSLParsing)
          
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

      def self.import_task_templates(assembly_hash)
        #TODO: just treating the default action
        #TODO: enhance to parse teh workflow, such as checking all components in workflow
        #are defined
        unless workflow =  assembly_hash["workflow"]
          return nil
        end

        #its ok to delete from assembly_hash/workflow
        if assembly_action = workflow.delete("assembly_action")
          unless  assembly_action == "create"
            raise ErrorUsage.new("Unexpected workflow task action (#{assembly_action})")
          end
        end
        task_template_ref = task_action = Task::Template.default_task_action()
        {
          task_template_ref => {
            "task_action" => task_action,
            "content" => workflow
          }
        }
      end

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
        ref,type,version = InternalForm.component_ref_type_and_version(cmp.kind_of?(Hash) ?  cmp.keys.first : cmp)
        display_name = ref

        #TODO: move this also to import_export_common
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
              (input_cmp.values.first["service_links"]||{}).each_pair do |link_def_type,targets|
                Array(targets).each do |target|
                  ret << AssemblyImportPortRef.parse_service_link(input_node_name,input_cmp_name,link_def_type => target)
                end
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
        ret =
          if cmp_input.kind_of?(Hash) 
            unless cmp_input.values.first.kind_of?(Hash)
              raise ErrorUsage.new("Parsing error with term (#{cmp_input.inspect})")
            end
            cmp_input.values.first["attributes"]||{}
          end
        ret||{}
      end
      
    end
  end
end; end
