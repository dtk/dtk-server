r8_require('../../factory_object_type')
module DTK
  class Assembly; class Template
    class Factory < self
      r8_nested_require('factory', 'non_default_attribute')
      extend FactoryObjectClassMixin
      include FactoryObjectMixin

      def self.get_or_create_service_module(project, service_module_name, opts = {})
        unless namespace = opts[:namespace]
          fail Error.new('Need to update code so that namespace passed in')
        end
        if service_module = get_service_module?(project, service_module_name, namespace)
          service_module
        else
          fail ErrorUsage.new("Unable to create assembly because service module (#{namespace}:#{service_module_name}) clone exists on local machine but missing from server. You should import service module or delete local clone and try again.") if opts[:local_clone_dir_exists]

          if opts[:mode] == :update
            fail ErrorUsage.new("Service module (#{service_module_name}) does not exist")
          end

          local_params = ModuleBranch::Location::LocalParams::Server.new(
            module_type: :service_module,
            module_name: service_module_name,
            namespace: namespace,
            version: nil
          )

          # TODO: look to remove :config_agent_type
          module_and_branch_info = ServiceModule.create_module(project, local_params, config_agent_type: ConfigAgent::Type.default_symbol)
          module_and_branch_info[:module_idh].create_object()
        end
      end

      # creates a new assembly template if it does not exist
      def self.create_or_update_from_instance(assembly_instance, service_module, assembly_name, opts = {})
        assembly_factory = create_assembly_factory(assembly_instance, service_module, assembly_name, opts)
        assembly_factory.raise_error_if_integrity_error()
        assembly_factory.create_assembly_template(opts)
      end

      def create_assembly_template(opts = {})
        add_content_for_clone!()
        create_assembly_template_aux(opts)
      end

      def set_object_attributes!(project_idh, assembly_instance, service_module, service_module_branch)
        @project_idh = project_idh
        @assembly_instance = assembly_instance
        @service_module = service_module
        @service_module_branch = service_module_branch
        @assembly_component_modules = assembly_instance.get_component_modules(get_version_info: true)
        @component_module_refs = service_module.get_component_module_refs()
        self
      end

      def raise_error_if_integrity_error
        raise_error_if_inconsistent_mod_refs()
      end

      private

      def raise_error_if_inconsistent_mod_refs
        mismatched_cmp_mods = []
        @assembly_component_modules.each do |cmp_mod|
          cmp_mod_name = cmp_mod[:display_name]
          if namespace = @component_module_refs.matching_component_module_namespace?(cmp_mod_name)
            if namespace != cmp_mod[:namespace_name]
              mismatch = {
                module_name: cmp_mod_name,
                template_ns: namespace,
                instance_ns: cmp_mod[:namespace_name]
              }
              mismatched_cmp_mods << mismatch
            end
          end
        end
        unless mismatched_cmp_mods.empty?
          err_msg = "Cannot push to service module (#{@service_module.get_field?(:display_name)}) because the following mismatches in namespaces:\n"
          mismatched_cmp_mods.each do |el|
            err_msg << " Component module (#{el[:module_name]}) in instance has namespace (#{el[:instance_ns]}), but namespace (#{el[:template_ns]}) in service module\n"
          end
          err_msg << "Alternatives are to push to another service module or change the service module's #{ModuleRefs.meta_filename_path()} file"
          fail ErrorUsage.new(err_msg)
        end
      end

      def self.create_assembly_factory(assembly_instance, service_module, assembly_name, opts = {})
        service_module_name = service_module.get_field?(:display_name)
        local_params = ModuleBranch::Location::LocalParams::Server.new(
          module_type: :service_module,
          module_name: service_module_name,
          namespace: service_module.module_namespace(),
          version: opts[:version]
        )
        service_module_branch = service_module.get_module_branch_from_local_params(local_params)
        project_idh = service_module.get_project().id_handle()

        assembly_mh = project_idh.create_childMH(:component)
        if ret = exists?(assembly_mh, service_module, assembly_name)
          if opts[:mode] == :create
            fail ErrorUsage.new("Assembly (#{assembly_name}) already exists in service module (#{service_module_name})")
          end
          ret.set_object_attributes!(project_idh, assembly_instance, service_module, service_module_branch)
        else
          if opts[:mode] == :update
            fail ErrorUsage.new("Assembly (#{assembly_name}) does not exist in service module (#{service_module_name})")
          end
          assembly_mh = project_idh.create_childMH(:component)
          hash_values = {
            project_project_id: project_idh.get_id(),
            ref: service_module.assembly_ref(assembly_name),
            display_name: assembly_name,
            type: 'composite',
            module_branch_id: service_module_branch[:id],
            component_type: Assembly.ret_component_type(service_module_name, assembly_name)
          }
          hash_values.merge!(description: opts[:description]) if opts[:description]
          ret = create(assembly_mh, hash_values)
          ret.set_object_attributes!(project_idh, assembly_instance, service_module, service_module_branch)
        end
      end

      public

      attr_reader :assembly_instance

      private

      attr_reader :project_idh, :service_module_branch

      def project_uri
        @project_uri ||= @project_idh.get_uri()
      end

      def add_content_for_clone!
        node_idhs = assembly_instance.get_nodes().map(&:id_handle)
        if node_idhs.empty?
          fail ErrorUsage.new("Cannot find any nodes associated with assembly (#{assembly_instance.get_field?(:display_name)})")
        end

        # 1) get a content object, 2) modify, and 3) persist
        port_links, dangling_links = Node.get_conn_port_links(node_idhs)
        # TODO: raise error to user if dangling link
        Log.error("dangling links #{dangling_links.inspect}") unless dangling_links.empty?

        task_templates = assembly_instance.get_task_templates_with_serialized_content()

        node_scalar_cols = FactoryObject::CommonCols + [:type, :node_binding_rs_id]
        node_mh = node_idhs.first.createMH()
        node_ids = node_idhs.map(&:get_id)

        # get assembly-level attributes
        assembly_level_attrs = assembly_instance.get_assembly_level_attributes().reject do |a|
          a[:attribute_value].nil?
        end

        # get node-level attributes
        ndx_node_level_attrs = {}
        Node.get_node_level_assembly_template_attributes(node_idhs).each do |r|
          (ndx_node_level_attrs[r[:node_node_id]] ||= []) << r
        end

        # get contained ports
        sp_hash = {
          cols: [:id, :display_name, :ports_for_clone],
          filter: [:oneof, :id, node_ids]
        }
        @ndx_ports = {}
        node_port_mapping = {}
        Model.get_objs(node_mh, sp_hash, keep_ref_cols: true).each do |r|
          port = r[:port].merge(link_def: r[:link_def])
          (node_port_mapping[r[:id]] ||= []) << port
          @ndx_ports[port[:id]] = port
        end

        # get contained components-non-default attribute candidates
        sp_hash = {
          cols: node_scalar_cols + [:cmps_and_non_default_attr_candidates],
          filter: [:oneof, :id, node_ids]
        }

        node_cmp_attr_rows = Model.get_objs(node_mh, sp_hash, keep_ref_cols: true)
        if node_cmp_attr_rows.empty?
          fail ErrorUsage.new('No components in the nodes being grouped to be an assembly template')
        end
        cmp_scalar_cols = node_cmp_attr_rows.first[:component].keys - [:non_default_attr_candidate]
        @ndx_nodes = {}
        node_cmp_attr_rows.each do |r|
          node_id = r[:id]
          @ndx_nodes[node_id] ||=
            r.hash_subset(*node_scalar_cols).merge(
              components: [],
              ports: node_port_mapping[node_id],
              attributes: ndx_node_level_attrs[node_id]
            )
          cmps = @ndx_nodes[node_id][:components]
          cmp_id = r[:component][:id]
          unless matching_cmp = cmps.find { |cmp| cmp[:id] == cmp_id }
            matching_cmp = r[:component].hash_subset(*cmp_scalar_cols).merge(non_default_attributes: [])
            cmps << matching_cmp
          end
          if attr_cand = r[:non_default_attr_candidate]
            if non_default_attr = NonDefaultAttribute.isa?(attr_cand, matching_cmp)
              matching_cmp[:non_default_attributes] << non_default_attr
            end
          end
        end
        update_hash = {
          nodes: @ndx_nodes.values,
          port_links: port_links,
          assembly_level_attributes: assembly_level_attrs
        }
        merge!(update_hash)
        merge!(task_templates: task_templates) unless task_templates.empty?
        self
      end

      # TODO: can collapse above and below; aboves looks like extra intermediate level
      def create_assembly_template_aux(opts = {})
        ret = nil
        nodes = self[:nodes].inject(DBUpdateHash.new) { |h, node| h.merge(create_node_content(node)) }
        port_links = self[:port_links].inject(DBUpdateHash.new) { |h, pl| h.merge(create_port_link_content(pl)) }
        task_templates = self[:task_templates].inject(DBUpdateHash.new) { |h, tt| h.merge(create_task_template_content(tt)) }
        assembly_level_attributes = self[:assembly_level_attributes].inject(DBUpdateHash.new) { |h, a| h.merge(create_assembly_level_attributes(a)) }

        # only need to mark as complete if assembly template exists already
        if assembly_template_idh = id_handle_if_object_exists?()
          assembly_template_id = assembly_template_idh.get_id()
          nodes.mark_as_complete({ assembly_id: assembly_template_id }, apply_recursively: true)
          port_links.mark_as_complete(assembly_id: assembly_template_id)
          task_templates.mark_as_complete(component_component_id: assembly_template_id)
          assembly_level_attributes.mark_as_complete(component_component_id: assembly_template_id)
        end

        @template_output = ServiceModule::AssemblyExport.create(self, project_idh, service_module_branch)
        assembly_ref = self[:ref]
        assembly_hash = hash_subset(:display_name, :type, :ui, :module_branch_id, :component_type)

        # description = self[:description]||@assembly_instance.get_field?(:description)
        description = self[:description] || self[:display_name]
        assembly_hash.merge!(description: description) if description

        assembly_hash.merge!(task_template: task_templates) unless task_templates.empty?
        assembly_hash.merge!(attribute: assembly_level_attributes) unless assembly_level_attributes.empty?
        assembly_hash.merge!(port_link: port_links) unless port_links.empty?
        @template_output.merge!(node: nodes, component: { assembly_ref => assembly_hash })
        module_refs_updated = @component_module_refs.update_object_if_needed!(@assembly_component_modules)

        Transaction do
          ret = @template_output.check_merge_conflicts(@assembly_instance, @service_module_branch)
          @template_output.save_to_model()
          if module_refs_updated
            @component_module_refs.update() # update the object model
            @component_module_refs.serialize_and_save_to_repo?(update_module_refs: true)
          end

          # serialize_and_save_to_repo? returns new_commit_sha
          @template_output.serialize_and_save_to_repo?(opts)
        end

        ret
      end

      def self.exists?(assembly_mh, service_module, template_name)
        ret = nil
        sp_hash = {
          cols: [:id, :group_id, :display_name],
          filter: [:and, [:eq, :service_id, service_module.id()]]
        }
        module_branches = get_objs(service_module.model_handle(:module_branch), sp_hash)
        return ret if module_branches.empty?

        service_module_name = service_module.get_field?(:display_name)
        component_type = component_type(service_module_name, template_name)
        sp_hash = {
          cols: [:id, :display_name, :group_id, :component_type, :project_project_id, :ref, :ui, :type, :module_branch_id],
          filter:           [:and,
                             [:eq, :type, 'composite'],
                             # Aldin: added ancestor_id==nil check to distinct between service instance (has ancestor_id) and assembly-template
                             # with same name (does not have ancestor_id)
                             [:eq, :ancestor_id, nil],
                             [:eq, :component_type, component_type],
                             [:oneof, :module_branch_id, module_branches.map(&:id)]]
        }
        if row = get_obj(assembly_mh, sp_hash, keep_ref_cols: true)
          subclass_model(row) # so that what is returned is object of type Assembly::Template::Factory
        end
      end

      def create_port_link_content(port_link)
        in_port = @ndx_ports[port_link[:input_id]]
        in_node_ref = node_ref(@ndx_nodes[in_port[:node_node_id]])
        in_port_ref = qualified_ref(in_port)
        out_port = @ndx_ports[port_link[:output_id]]
        out_node_ref = node_ref(@ndx_nodes[out_port[:node_node_id]])
        out_port_ref = qualified_ref(out_port)

        assembly_ref = self[:ref]
        port_link_ref_info =  {
          assembly_template_ref: assembly_ref,
          in_node_ref: in_node_ref,
          in_port_ref: in_port_ref,
          out_node_ref: out_node_ref,
          out_port_ref: out_port_ref
        }
        port_link_ref = PortLink.port_link_ref(port_link_ref_info)
        port_link_hash = {
          '*input_id' => "/node/#{in_node_ref}/port/#{in_port_ref}",
          '*output_id' => "/node/#{out_node_ref}/port/#{out_port_ref}",
          '*assembly_id' => "/component/#{assembly_ref}"
        }
        { port_link_ref => port_link_hash }
      end

      def get_ndx_target_port_refs(relative_port_refs_x)
        relative_port_refs = relative_port_refs_x.map { |pr| pr.gsub(/^\//, '') }
        IDInfoTable.get_ndx_ids_matching_relative_uris(@project_idh, project_uri(), relative_port_refs).inject({}) do |h, (k, v)|
          h.merge("/#{k}" => v)
        end
      end

      def create_task_template_content(task_template)
        ref, create_hash = Task::Template.ref_and_create_hash(task_template[:content], task_template[:task_action])
        { ref => create_hash }
      end

      def create_assembly_level_attributes(attr)
        ref = display_name = attr[:display_name]
        create_hash = {
          display_name: display_name,
          value_asserted: attr[:attribute_value],
          data_type: attr[:data_type] || Attribute::Datatype.default()
        }
        { ref => create_hash }
      end

      def create_node_content(node)
        node_ref = node_ref(node)
        cmp_refs = node[:components].inject({}) { |h, cmp| h.merge(create_component_ref_content(cmp)) }
        ports = (node[:ports] || []).inject({}) { |h, p| h.merge(create_port_content(p)) }
        node_attrs = (node[:attributes] || []).inject({}) { |h, a| h.merge(create_node_attribute_content(a)) }
        node_hash = Aux.hash_subset(node, [:display_name, :node_binding_rs_id])
        node_type =
          if node[:display_name].eql?('assembly_wide')
            'assembly_wide'
          else
            node.is_node_group?() ? Node::Type::NodeGroup.stub : Node::Type::Node.stub
          end
        node_hash.merge!(
          '*assembly_id' => "/component/#{self[:ref]}",
          :type          => node_type,
          :component_ref => cmp_refs,
          :port          => ports,
          :attribute     => node_attrs
        )
        { node_ref => node_hash }
      end

      def create_port_content(port)
        port_ref = qualified_ref(port)
        port_hash = Aux.hash_subset(port, [:display_name, :description, :type, :direction, :link_type, :component_type])
        port_hash.merge!(link_def_id: port[:link_def][:ancestor_id]) if port[:link_def]
        { port_ref => port_hash }
      end

      def create_node_attribute_content(attr)
        attr_ref = attr[:display_name]
        attr_hash = Aux.hash_subset(attr, [:display_name, :value_asserted, :value_derived, :data_type])
        { attr_ref => attr_hash }
      end

      def create_component_ref_content(cmp)
        cmp_ref_ref = ComponentRef.ref_from_component_hash(cmp)
        cmp_ref_hash = Aux.hash_subset(cmp, [:display_name, :description, :component_type])
        cmp_template_id = cmp[:ancestor_id]
        cmp_ref_hash.merge!(component_template_id: cmp_template_id)
        attrs = cmp[:non_default_attributes]
        unless attrs.nil? || attrs.empty?
          NonDefaultAttribute.add_to_cmp_ref_hash!(cmp_ref_hash, self, attrs, cmp_template_id)
        end
        { cmp_ref_ref => cmp_ref_hash }
      end

      def node_ref(node)
        assembly_template_node_ref(self[:ref], node[:display_name])
      end
    end
  end; end
end
