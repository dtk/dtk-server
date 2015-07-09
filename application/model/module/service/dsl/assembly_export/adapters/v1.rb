module DTK
  class ServiceModule; class AssemblyExport
    class V1 < self
      private

      def serialize
        assembly_hash = assembly_output_hash()
        node_bindings_hash = node_bindings_output_hash()
        ref = assembly_hash.delete(:ref)
        SimpleOrderedHash.new(
         [
          { node_bindings: node_bindings_hash },
          { assemblies: { ref => assembly_hash } }
         ])
      end

      def assembly_output_hash
        ret = SimpleOrderedHash.new()
        ret[:name] = assembly_hash()[:display_name]
        ret[:ref] = assembly_ref()
        # TODO: may put in version info
        #  "#{impl[:module_name]}-#{version}"
        # end

        # add assembly level attributes
        # TODO: stub

        # add nodes and components
        ret[:nodes] = self[:node].inject(SimpleOrderedHash.new()) do |h, (_node_ref, node_hash)|
          node_name = node_hash[:display_name]
          cmp_info = node_hash[:component_ref].values.map { |cmp| component_output_form(cmp) }
          h.merge(node_name => { components: cmp_info })
        end

        # add port links
        ret[:port_links] = self[:port_link].values.map do |pl|
           input_qual_port_ref = pl['*input_id']
           output_qual_port_ref = pl['*output_id']
           { port_output_form(input_qual_port_ref, :input) => port_output_form(output_qual_port_ref, :output) }
         end
        ret
      end

      def assembly_ref
        self[:component].keys.first
      end

      def node_bindings_output_hash
        sp_hash = {
          cols: [:id, :ref],
          filter: [:oneof, :id, self[:node].values.map { |n| n[:node_binding_rs_id] }]
        }
        # TODO: may get this info in earlier phase
        node_binding_rows = Model.get_objs(@container_idh.createMH(:node_binding_ruleset), sp_hash, keep_ref_cols: true)
        node_binding_id_to_ref = node_binding_rows.inject({}) { |h, r| h.merge(r[:id] => r[:ref]) }
        assembly_ref = assembly_ref()
        self[:node].inject({}) do |h, (_node_ref, node_hash)|
          h.merge("#{assembly_ref}#{Seperators[:assembly_node]}#{node_hash[:display_name]}" => node_binding_id_to_ref[node_hash[:node_binding_rs_id]])
        end
      end

      def port_output_form(qualified_port_ref, _dir)
        # TODO: does this need fixing up in case a component can appear multiple times
        # TODO: assumption that port_ref == display_name
        port_ref = qualified_port_ref.split('/').last
        p = Port.parse_port_display_name(port_ref)
        node_ref = (qualified_port_ref =~ Regexp.new('^/node/([^/]+)'); Regexp.last_match(1))
        unless matching_node = self[:node].find { |ref, _hash| ref == node_ref }
          fail Error.new("Cannot find matching node for node ref #{node_ref})")
        end
        node_name = matching_node[1][:display_name]
        cmp_name = component_name_output_form(p[:component_type])
        sep = Seperators #just for succinctness
        "#{node_name}#{sep[:node_component]}#{cmp_name}#{sep[:component_port]}#{p[:link_def_ref]}"
      end

      def attr_overrides_output_form(attr_overrides)
        av_list = attr_overrides.values.map { |attr| { attr[:display_name] => attr[:attribute_value] } }.sort { |a, b| a.keys.first <=> b.keys.first }
        SimpleOrderedHash.new(av_list)
      end
    end
  end; end
end
