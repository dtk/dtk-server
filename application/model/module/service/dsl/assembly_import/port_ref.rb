module DTK; class ServiceModule
  class AssemblyImport
    class PortRef < SimpleHashObject
      include ServiceDSLCommonMixin

      def self.parse(port_ref,assembly_id_or_opts={})
        assembly_id = nil
        err_opts = Opts.new
        if assembly_id_or_opts.is_a?(Hash)
          assembly_id = assembly_id_or_opts[:assembly_id]
          err_opts.merge!(assembly_id_or_opts)
        else
          assembly_id = assembly_id_or_opts
        end

        # TODO: may need to update this to handle port refs with titles
        if port_ref =~ PortRefRegex
          node = $1; cmp_name = $2; link_def_ref = $3
          hash = {node: node,component_type: component_type_internal_form(cmp_name),link_def_ref: link_def_ref}
          if assembly_id
            hash.merge!(assembly_id: assembly_id)
          end
          new(hash)
        else
          raise ParsingError.new("Ill-formed port ref (#{port_ref})",err_opts)
        end
      end
      def self.parse_component_link(input_node,input_cmp_name,component_link_hash,opts={})
        err_opts = Opts.new(opts).slice(:file_path)
        unless component_link_hash.size == 1
          raise ParsingError.new('Ill-formed component link ?1',component_link_hash,err_opts)
        end
        link_def_ref = component_link_hash.keys.first

        cmp_link_value = component_link_hash.values.first
        cmp_link_value = "assembly_wide#{Seperators[:node_component]}#{cmp_link_value}" unless cmp_link_value.include?(Seperators[:node_component])

        if cmp_link_value =~ ServiceLinkTarget
          output_node = $1; output_cmp_name = $2
          input = parsed_endpoint(input_node,input_cmp_name,link_def_ref)
          output = parsed_endpoint(output_node,output_cmp_name,link_def_ref)
          {input: input, output: output}
        else
          raise ParsingError.new("Ill-formed component link ?file_path ?1\nIt should have form: \n  ?2",component_link_hash,ServiceLinkLegalForm,err_opts)
        end
      end
      PortRefRegex = Regexp.new("(^.+)#{Seperators[:node_component]}(.+)#{Seperators[:component_link_def_ref]}(.+$)")
      ServiceLinkTarget = Regexp.new("(^.+)#{Seperators[:node_component]}(.+$)")
      ServiceLinkLegalForm = 'LinkType: Node/Component'

      # ports are augmented with field :parsed_port_name
      def matching_id(aug_ports,opts={})
        if port_or_error = matching_port(aug_ports,opts)
          port_or_error.is_a?(ParsingError) ? port_or_error : port_or_error[:id]
        end
      end

      # ports are augmented with field :parsed_port_name
      def matching_port(aug_ports,opts={})
        aug_ports.find{|port|matching_port__match?(port)} || matching_port__error(opts)
      end

      private

      def self.parsed_endpoint(node,cmp_name,link_def_ref)
        component_type,title = ComponentTitle.parse_component_display_name(cmp_name)
        ret_hash = {node: node,component_type: component_type_internal_form(component_type), link_def_ref: link_def_ref}
        ret_hash.merge!(title: title) if title
        new(ret_hash)
      end
      def self.component_type_internal_form(cmp_type_ext_form)
        # TODO: this does not take into account that there could be a version on cmp_type_ext_form
        InternalForm.component_ref(cmp_type_ext_form)
      end

      def matching_port__error(opts={})
        if opts[:do_not_throw_error]
          opts_err = Opts.new(opts).slice(:file_path)
          ParsingError::BadComponentLink.new(self[:link_def_ref],opts[:base_cmp_name],opts_err)
        else
          Error.new("Cannot find match to (#{self.inspect})")
        end
      end

      def matching_port__match?(aug_port)
        p = aug_port[:parsed_port_name]
        node = aug_port[:node][:display_name]

        matching_port__match_on_assembly_id?(aug_port) &&
          self[:node] == node &&
          self[:component_type] == p[:component_type] &&
          self[:link_def_ref] == p[:link_def_ref] &&
          self[:title] == p[:title]
      end

      def matching_port__match_on_assembly_id?(aug_port)
        self[:assembly_id].nil? || (self[:assembly_id] == aug_port[:assembly_id])
      end

      def raise_or_ret_error(err_class,args,opts={})
        opts_file_path = Aux::hash_subset(opts,[:file_path])
        err = err_class.new(*args,opts_file_path)
        opts[:do_not_throw_error] ? err : raise(err)
      end

      class AddOn < self
        # returns assembly ref, port_ref
        def self.parse(add_on_port_ref,assembly_list)
          assembly_name,port_ref = (add_on_port_ref =~ AOPortRefRegex; [$1,$2])
          unless assembly_match = assembly_list.find{|a|a[:display_name] == assembly_name}
            assembly_names = assembly_list.map{|a|a[:display_name]}
            Log.error("Assembly name in add-on port link (#{assembly_name}) is illegal; must be one of (#{assembly_names.join(',')})")
            #            raise ErrorUsage.new("Assembly name in add-on port link (#{assembly_name}) is illegal; must be one of (#{assembly_names.join(',')})")
          end
          [assembly_name,super(port_ref,assembly_match[:id])]
        end
        AOSep = Seperators[:assembly_node]
        AOPortRefRegex = Regexp.new("(^[^#{AOSep}]+)#{AOSep}(.+$)")
      end
    end
  end
end; end
