module DTK; class ServiceModule
  class AssemblyImport
    class V2 < self
      def self.assembly_iterate(module_name,hash_content,&block)
        assembly_hash = (hash_content["assembly"]||{}).merge(Aux::hash_subset(hash_content,["name","workflow"]))
        assembly_ref = ServiceModule.assembly_ref(module_name,hash_content["name"])
        assemblies_hash = {assembly_ref => assembly_hash}
        node_bindings_hash = hash_content["node_bindings"]
        block.call(assemblies_hash,node_bindings_hash)
      end

      def self.import_assembly_top(serialized_assembly_ref,assembly_hash,module_branch,module_name,opts={})
        ret = super(serialized_assembly_ref,assembly_hash,module_branch,module_name,opts)
        ret_assembly_hash = ret.values.first
        ret_assembly_hash.merge!("task_template" => import_task_templates(assembly_hash))
        ret
      end

      def self.import_port_links(assembly_idh,assembly_ref,assembly_hash,ports,opts={})
        #augment ports with parsed display_name
        augment_with_parsed_port_names!(ports)
        port_links = parse_component_links(assembly_hash).inject(DBUpdateHash.new) do |h,parsed_service_link|
          input = parsed_service_link[:input]
          output = parsed_service_link[:output]
          opts_matching_id = opts.merge(:do_not_throw_error => true)

          input_id = input.matching_id(ports,opts_matching_id)
          return input_id if input_id.is_a?(ErrorUsage::DSLParsing)
          
          output_id = output.matching_id(ports,opts_matching_id.merge(:is_output => true))
          return output_id if output_id.is_a?(ErrorUsage::DSLParsing)

          pl_ref = PortLink.ref_from_ids(input_id,output_id)
          pl_hash = {"input_id" => input_id,"output_id" => output_id, "assembly_id" => assembly_idh.get_id()}
          h.merge(pl_ref => pl_hash)
        end
        port_links.mark_as_complete(:assembly_id=>@existing_assembly_ids)
        {assembly_ref => {"port_link" => port_links}}
      end

     private
      include ServiceDSLCommonMixin

      def self.import_task_templates(assembly_hash)
        ret = DBUpdateHash.new()
        #TODO: just treating the default action
        #TODO: enhance to parse the workflow, such as checking all components in workflow
        #are defined
        if workflow = assembly_hash["workflow"]
          #its ok to delete from assembly_hash/workflow
          if assembly_action = workflow.delete("assembly_action")
            unless  assembly_action == "create"
              raise ErrorUsage.new("Unexpected workflow task action (#{assembly_action})")
            end
          end
          task_template_ref = task_action = Task::Template.default_task_action()
          update = {
            task_template_ref => {
              "task_action" => task_action,
              "content" => workflow
            }
          }
          ret.merge!(update)
        end
        ret.mark_as_complete()
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

        #TODO: move this also to dsl/common
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

      def self.parse_component_links(assembly_hash)
        ret = Array.new
        (assembly_hash["nodes"]||{}).each_pair do |input_node_name,node_hash|
          components = node_hash["components"]||[]
          components = [components] unless components.kind_of?(Array)
          components.each do |input_cmp|
            if input_cmp.kind_of?(Hash) 
              input_cmp_name = input_cmp.keys.first
              (input_cmp.values.first["service_links"]||{}).each_pair do |link_def_type,targets|
                Array(targets).each do |target|
                  component_link_hash = {link_def_type => target}
                  ret << AssemblyImportPortRef.parse_component_link(input_node_name,input_cmp_name,component_link_hash)
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
              raise ErrorUsage::DSLParsing.new("Parsing error after component term (#{cmp_input.keys.first})")
            end
            cmp_input.values.first["attributes"]||{}
          end
        ret||{}
      end
      
    end
  end
end; end
