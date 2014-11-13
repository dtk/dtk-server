module DTK; class ServiceModule
  class AssemblyImport
    class V2 < self
      def self.assembly_iterate(service_module,hash_content,&block)
        assembly_hash = (hash_content["assembly"]||{}).merge(Aux::hash_subset(hash_content,["name","workflow"]))
        assembly_ref = service_module.assembly_ref(hash_content["name"])
        assemblies_hash = {assembly_ref => assembly_hash}
        node_bindings_hash = hash_content["node_bindings"]
        block.call(assemblies_hash,node_bindings_hash)
      end

      def self.import_assembly_top(assembly_ref,assembly_hash,module_branch,module_name,opts={})
        ret = super(assembly_ref,assembly_hash,module_branch,module_name,opts)
        ret_assembly_hash = ret.values.first
        ret_assembly_hash.merge!("task_template" => import_task_templates(assembly_hash))
        ret
      end

      def self.import_port_links(assembly_idh,assembly_ref,assembly_hash,ports,opts={})
        # augment ports with parsed display_name
        augment_with_parsed_port_names!(ports)
        port_links = parse_component_links(assembly_hash,opts).inject(DBUpdateHash.new) do |h,component_link_info|
          parsed_component_link = component_link_info[:parsed_component_link]
          base_cmp_name = component_link_info[:base_cmp_name]
          input = parsed_component_link[:input]
          output = parsed_component_link[:output]
          opts_matching_port = opts.merge(:do_not_throw_error => true,:base_cmp_name => base_cmp_name)

          input_port_hash = input.matching_port(ports,opts_matching_port)
          return input_port_hash if ParsingError.is_error?(input_port_hash)
          
          output_port_hash = output.matching_port(ports,opts_matching_port.merge(:is_output => true))
          return output_port_hash if ParsingError.is_error?(output_port_hash)

          port_link_ref_info =  {
            :assembly_template_ref => assembly_idh.create_object().get_field?(:ref),
            :in_node_ref => input_port_hash[:node].get_field?(:ref),
            :in_port_ref => Port.ref_from_display_name(input_port_hash[:display_name]),
            :out_node_ref => output_port_hash[:node].get_field?(:ref),
            :out_port_ref => Port.ref_from_display_name(output_port_hash[:display_name])
          }
          pl_ref = PortLink.port_link_ref(port_link_ref_info)
          pl_hash = {
            "input_id" => input_port_hash[:id],
            "output_id" => output_port_hash[:id],
            "assembly_id" => assembly_idh.get_id()
          }
          h.merge(pl_ref => pl_hash)
        end
        port_links.mark_as_complete(:assembly_id=>@existing_assembly_ids)
        {assembly_ref => {"port_link" => port_links}}
      end

     private
      include ServiceDSLCommonMixin

      def self.import_task_templates(assembly_hash)
        ret = DBUpdateHash.new()
        # TODO: just treating the default action
        # TODO: enhance to parse the workflow, such as checking all components in workflow
        # are defined
        if workflow = assembly_hash["workflow"]
          # its ok to delete from assembly_hash/workflow
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

      def self.component_ref_parse(cmp)
        cmp_type_ext_form = (cmp.kind_of?(Hash) ?  cmp.keys.first : cmp)
        component_ref_info = InternalForm.component_ref_info(cmp_type_ext_form)
        type = component_ref_info[:component_type]
        title = component_ref_info[:title]
        version = component_ref_info[:version]
        ref = ComponentRef.ref(type,title)
        display_name = ComponentRef.display_name(type,title)
        ret = {:component_type => type, :ref => ref, :display_name => display_name}
        ret.merge!(:version => version) if version
        ret.merge!(:component_title => title) if title
        ret
      end

      # returns Array with each element being Hash with keys :parsed_component_link, :base_cmp_name
      def self.parse_component_links(assembly_hash,opts={})
        ret = Array.new
        (assembly_hash["nodes"]||{}).each_pair do |input_node_name,node_hash|
          components = node_hash["components"]||[]
          components = [components] unless components.kind_of?(Array)
          components.each do |base_cmp|
            if base_cmp.kind_of?(Hash) 
              base_cmp_name = base_cmp.keys.first
              (base_cmp.values.first["service_links"]||{}).each_pair do |link_def_type,targets|
                Array(targets).each do |target|
                  component_link_hash = {link_def_type => target}
                  parsed_component_link = PortRef.parse_component_link(input_node_name,base_cmp_name,component_link_hash)
                  ret << {:parsed_component_link => parsed_component_link, :base_cmp_name => base_cmp_name}
                end
              end
            end
          end
        end
        ret
      end

      def self.node_to_node_binding_rs(assembly_ref,node_bindings_hash,opts={})
        (node_bindings_hash||{}).inject(Hash.new) do |h,(node,v)|
          merge_hash = 
            if v.kind_of?(String) then {node => v}
            elsif v.kind_of?(Hash)
              Log.error("Not implemented yet have node bindings with explicit properties")
              Hash.new
            else
              raise ParsingError.new("Unexpected form of node binding",opts_file_path(opts))
            end
          h.merge(merge_hash)
        end
      end

      def self.ret_component_hash(cmp_input)
        ret = Hash.new
        if cmp_input.kind_of?(Hash) 
          ret = cmp_input.values.first
          unless ret.kind_of?(Hash)
            err_msg = "Parsing error after component term (#{cmp_input.keys.first}) in: ?1"
            if ret.nil?
              err_msg << "\nThere is a nil value after this term"
            end
            raise ParsingError.new(err_msg,cmp_input)
          end
        end
        ret
      end

      def self.ret_attribute_overrides(cmp_input)
        ret_component_hash(cmp_input)["attributes"]||{}
      end
    end
  end
end; end
