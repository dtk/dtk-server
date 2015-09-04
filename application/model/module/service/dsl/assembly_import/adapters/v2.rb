module DTK; class ServiceModule
  class AssemblyImport
    class V2 < self
      def self.assembly_iterate(service_module, hash_content, &block)
        assembly_hash = (hash_content['assembly'] || {}).merge(Aux.hash_subset(hash_content, ['name', 'description', 'workflow']))
        assembly_ref = service_module.assembly_ref(hash_content['name'])
        assemblies_hash = { assembly_ref => assembly_hash }
        node_bindings_hash = hash_content['node_bindings']
        block.call(assemblies_hash, node_bindings_hash)
      end

      def self.import_assembly_top(assembly_ref, assembly_hash, module_branch, module_name, opts = {})
        ret = super(assembly_ref, assembly_hash, module_branch, module_name, opts)
        ret_assembly_hash = ret.values.first
        ret_assembly_hash.merge!('task_template' => import_task_templates(assembly_hash).mark_as_complete())
        ret
      end

      # TODO: DTK-2234: need to refine how dangling component links (port_links) are handled;
      # options are:
      # 1) throw an error
      # 2) remove the dangling links and log console error
      # 3) remove the dangling links, and send user warning
      # 4) remove the dangling links, but store them in what would be a new dangling link table, which could be used for auto-complete
      #    and late-binding; for this we need to determine if error raised is because link def not defined or because there is a pointer to a component
      #    that does not exist; for former that would just be an error
      # Implemnting initially 2 because easiest to implement and less 'disruptive' than 1
      def self.import_port_links(assembly_idh, assembly_ref, assembly_hash, ports, opts = {})
        # augment ports with parsed display_name
        augment_with_parsed_port_names!(ports)
        port_links = DBUpdateHash.new
        parse_component_links(assembly_hash, opts).each do |component_link_info|
          error_or_nil, input_port_hash, output_port_hash = find_matching_port_info(component_link_info, ports, opts)
          unless error_or_nil
            port_links.merge!(port_link_to_add(assembly_idh, input_port_hash, output_port_hash))
          else
            Log.error_pp(error_or_nil)
          end
        end

        port_links.mark_as_complete(assembly_id: @existing_assembly_ids)
        { assembly_ref => { 'port_link' => port_links } }
      end

      private

      include ServiceDSLCommonMixin

      # returns [error_or_nil, input_port_hash, output_port_hash]
      # if error_or_nil s error then input_port_hash and/or output_port_hash can be nil
      def self.find_matching_port_info(component_link_info, ports, opts = {})
        error_or_nil = input_port_hash = output_port_hash = nil

        base_cmp_name         = component_link_info[:base_cmp_name]
        parsed_component_link = component_link_info[:parsed_component_link]
        input                 = parsed_component_link[:input]
        output                = parsed_component_link[:output]

        opts_matching_port = opts.merge(do_not_throw_error: true, base_cmp_name: base_cmp_name)

        input_port_hash = input.matching_port(ports, opts_matching_port)
        if ParsingError.is_error?(input_port_hash)
          error_or_nil = input_port_hash
          return([error_or_nil, input_port_hash, output_port_hash])
        end
        
        output_port_hash = output.matching_port(ports, opts_matching_port.merge(is_output: true))
        if ParsingError.is_error?(output_port_hash)
          error_or_nil = output_port_hash
          return([error_or_nil, input_port_hash, output_port_hash])
        end

        [error_or_nil, input_port_hash, output_port_hash]
      end

      def self.port_link_to_add(assembly_idh, input_port_hash, output_port_hash)
        port_link_ref_info =  {
          assembly_template_ref: assembly_idh.create_object().get_field?(:ref),
          in_node_ref:           input_port_hash[:node].get_field?(:ref),
          in_port_ref:           Port.ref_from_display_name(input_port_hash[:display_name]),
          out_node_ref:          output_port_hash[:node].get_field?(:ref),
          out_port_ref:          Port.ref_from_display_name(output_port_hash[:display_name])
        }
        pl_ref = PortLink.port_link_ref(port_link_ref_info)
        pl_hash = {
          'input_id'    => input_port_hash[:id],
          'output_id'   => output_port_hash[:id],
          'assembly_id' => assembly_idh.get_id()
        }
        {pl_ref => pl_hash}
      end

      def self.import_task_templates(assembly_hash, opts = {})
        ret = DBUpdateHash.new()
        # TODO: just treating the default action
        # TODO: enhance to parse the workflow, such as checking all components in workflow
        # are defined
        if workflow = assembly_hash['workflow']
          # its ok to delete from assembly_hash/workflow
          if assembly_action = workflow.delete('assembly_action')
            unless  assembly_action == 'create'
              fail ErrorUsage.new("Unexpected workflow task action (#{assembly_action})")
            end
          end

          if opts[:service_module_workflow]
            task_template_ref = task_action = validate_service_module_workflow(workflow)
          else
            task_template_ref = task_action = Task::Template.default_task_action()
          end

          update = {
            task_template_ref => {
              'task_action' => task_action,
              'content' => workflow
            }
          }
          ret.merge!(update)
        end
        ret.mark_as_complete()
      end

      def self.validate_service_module_workflow(workflow)
        name = workflow['name']
        fail ErrorUsage.new("Unexpected that service_module workflow does not have name parameter.") unless name
        fail ErrorUsage.new("Service module workflow cannot have 'create' action.") if name.eql?('create')
        name
      end

      def self.pp_port_ref(port_ref)
        ret = "#{port_ref[:node]}/#{port_ref[:component_type].gsub(/__/, '::')}"
        if title = port_ref[:title]
          ret << "[#{title}]"
        end
        ret
      end

      def self.component_ref_parse(cmp)
        cmp_type_ext_form = (cmp.is_a?(Hash) ? cmp.keys.first : cmp)
        component_ref_info = InternalForm.component_ref_info(cmp_type_ext_form)
        type = component_ref_info[:component_type]
        title = component_ref_info[:title]
        version = component_ref_info[:version]
        ref = ComponentRef.ref(type, title)
        display_name = ComponentRef.display_name(type, title)
        ret = { component_type: type, ref: ref, display_name: display_name }
        ret.merge!(version: version) if version
        ret.merge!(component_title: title) if title
        ret
      end

      # returns Array with each element being Hash with keys :parsed_component_link, :base_cmp_name
      def self.parse_component_links(assembly_hash, _opts = {})
        ret = []
        (assembly_hash['nodes'] || {}).each_pair do |input_node_name, node_hash|
          components = node_hash['components'] || []
          components = [components] unless components.is_a?(Array)
          components.each do |base_cmp|
            if base_cmp.is_a?(Hash)
              base_cmp_name = base_cmp.keys.first
              (base_cmp.values.first['service_links'] || {}).each_pair do |link_def_type, targets|
                Array(targets).each do |target|
                  component_link_hash = { link_def_type => target }
                  parsed_component_link = PortRef.parse_component_link(input_node_name, base_cmp_name, component_link_hash)
                  ret << { parsed_component_link: parsed_component_link, base_cmp_name: base_cmp_name }
                end
              end
            end
          end
        end
        ret
      end

      def self.node_to_node_binding_rs(_assembly_ref, node_bindings_hash, opts = {})
        (node_bindings_hash || {}).inject({}) do |h, (node, v)|
          merge_hash =
            if v.is_a?(String) then { node => v }
            elsif v.is_a?(Hash)
              Log.error('Not implemented yet have node bindings with explicit properties')
              {}
            else
              fail ParsingError.new('Unexpected form of node binding', opts_file_path(opts))
            end
          h.merge(merge_hash)
        end
      end

      def self.ret_component_hash(cmp_input)
        ret = {}
        if cmp_input.is_a?(Hash)
          ret = cmp_input.values.first
          unless ret.is_a?(Hash)
            err_msg = "Parsing error after component term (#{cmp_input.keys.first}) in: ?1"
            if ret.nil?
              err_msg << "\nThere is a nil value after this term"
            end
            fail ParsingError.new(err_msg, cmp_input)
          end
        end
        ret
      end

      def self.ret_attribute_overrides(cmp_input)
        ret_component_hash(cmp_input)['attributes'] || {}
      end
    end
  end
end; end
