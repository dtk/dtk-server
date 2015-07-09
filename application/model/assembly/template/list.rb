module DTK
  class Assembly; class Template
    class List < self
      def self.list(assembly_mh,opts={})
        assembly_mh = assembly_mh.createMH(:assembly_template) # to insure right mh type
        opts = opts.merge(cols: [:id, :group_id,:display_name,:component_type,:module_branch_id,:service_module,list_virtual_column?(opts[:detail_level])].compact)
        assembly_rows = get(assembly_mh,opts)
        if opts[:detail_level] == 'attributes'
          attr_rows = get_component_attributes(assembly_mh,assembly_rows)
          list_aux(assembly_rows,attr_rows,opts)
        else
          list_aux__simple(assembly_rows,opts)
        end
      end

      def self.list_modules(assembly_templates)
        components = []
        assembly_templates.each do |assembly|
          components << assembly.info_about(:components)
        end
        components.flatten
      end

      def self.list_components(assembly_template)
        sp_hash = {
          filter: [:eq,:id,assembly_template.id()]
        }
        mh = assembly_template.model_handle
        aug_component_refs = get_augmented_component_refs(mh,sp_hash)
        aug_component_refs.map do |r|
          cmp_template = r[:component_template]
          node_name    = r[:node].is_assembly_wide_node?() ? '' : "#{r[:node][:display_name]}/"
          display_name = "#{node_name}#{r.display_name_print_form()}"
          version = ModuleBranch.version_from_version_field(cmp_template[:version])
          cmp_template.hash_subset(:id).merge(display_name: display_name, version: version)
        end.sort{|a,b|a[:display_name] <=> b[:display_name]}
      end

      def self.list_nodes(assembly_template)
        sp_hash = {cols: [:node_templates]}
        assembly_template.get_objs(sp_hash).map do |r|
          el = r[:node].hash_subset(:id,:display_name)
          el[:dtk_client_hidden] = el.is_assembly_wide_node?()
          case r[:node][:type]
            when 'node_group_stub'
              el.merge!(type: 'node_group')
            when 'stub'
              el.merge!(type: 'node')
          end
          if binding = r[:node_binding]
            binding_fields = binding.hash_subset(:os_type,display_name: :template_name)
            common_fields = binding.ret_common_fields_or_that_varies()
            common_fields_to_add = Aux::hash_subset(common_fields,[{type: :template_type},:image_id,:size,:region]).reject{|_k,v|v == :varies}
            binding_fields.merge!(common_fields_to_add)
            el.merge!(binding_fields)
          end
          el
        end.sort{|a,b|a[:display_name] <=> b[:display_name]}
      end

      private

      def self.get_component_attributes(assembly_mh,template_assembly_rows,opts={})
        # get attributes on templates (these are defaults)
        ret = get_default_component_attributes(assembly_mh,template_assembly_rows,opts)

        # get attribute overrides
        sp_hash = {
          cols: [:id,:display_name,:attribute_value,:attribute_template_id],
          filter: [:oneof, :component_ref_id,template_assembly_rows.map{|r|r[:component_ref][:id]}]
        }
        attr_override_rows = Model.get_objs(assembly_mh.createMH(:attribute_override),sp_hash)
        unless attr_override_rows.empty?
          ndx_attr_override_rows = attr_override_rows.inject({}) do |h,r|
            h.merge(r[:attribute_template_id] => r)
          end
          ret.each do |r|
            if override = ndx_attr_override_rows[r[:id]]
              r.merge!(attribute_value: override[:attribute_value], is_instance_value: true)
            end
          end
        end
        ret
      end

      def self.list_aux__simple(assembly_rows,opts={})
        ndx_ret = {}
        if opts[:detail_level] == 'components'
          raise Error.new('list assembly templates at component level not treated')
        end
        include_nodes = ['nodes'].include?(opts[:detail_level])
        pp_opts = Aux.hash_subset(opts,[:no_module_prefix,:version_suffix])
        assembly_rows.each do |r|
          # TODO: hack to create a Assembly object (as opposed to row which is component); should be replaced by having
          # get_objs do this (using possibly option flag for subtype processing)
          pntr = ndx_ret[r[:id]] ||= r.id_handle.create_object().merge(display_name: pretty_print_name(r,pp_opts),ndx_nodes: {})
          pntr.merge!(module_branch_id: r[:module_branch_id]) if r[:module_branch_id]
          # TODO: should replace with something more robust to find namespace
          if namespace = Namespace.namespace_from_ref?(r[:service_module][:ref])
            pntr.merge!(namespace: namespace)
          end

          if version = pretty_print_version(r)
            pntr.merge!(version: version)
          end
          next unless include_nodes
          node_id = r[:node][:id]
          unless node = pntr[:ndx_nodes][node_id]
            node = pntr[:ndx_nodes][node_id] = {
              node_name: r[:node][:display_name],
              node_id: node_id
            }
            node[:external_ref] = r[:node][:external_ref] if r[:node][:external_ref]
            node[:os_type] = r[:node][:os_type] if r[:node][:os_type]
          end
        end

        unsorted = ndx_ret.values.map do |r|
          el = r.slice(:id,:display_name,:module_branch_id,:version,:namespace)
          include_nodes ? el.merge(nodes: r[:ndx_nodes].values) : el
        end
        opts[:no_sorting] ? unsorted : unsorted.sort{|a,b|a[:display_name] <=> b[:display_name]}
      end
    end
  end
end; end
