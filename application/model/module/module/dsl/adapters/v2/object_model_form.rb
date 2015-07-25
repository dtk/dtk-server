# TODO: this does some conversion of form; should determine what shoudl be done here versus subsequent parser phase
# TODO: does not check for extra attributes
module DTK; class ModuleDSL; class V2
  class ObjectModelForm < ModuleDSL::ObjectModelForm
    r8_nested_require('object_model_form', 'attribute_fields')

    def self.convert(input_hash)
      new.convert(input_hash)
    end
    def convert(input_hash)
      component().new(input_hash.req(:module)).convert(input_hash['components'], context(input_hash))
    end

    def self.convert_attribute_mapping(input_am, base_cmp, dep_cmp, opts = {})
      choice().new.convert_attribute_mapping(input_am, base_cmp, dep_cmp, opts)
    end

    private

    # can be overwritten
    def context(_input_hash)
      {}
    end

    def component
      self.class::Component
    end

    def choice
      self.class::Choice
    end

    # returns a subset or hash for all keys listed; if an extyra keys then null signifying error condition is returned
    # '*' means required
    # e.g., keys ["*module","version"]
    def hash_contains?(hash, keys)
      req_keys = keys.inject({}) { |h, r| h.merge(r.gsub(/^\*/, '') => (r =~ /^\*/) ? 1 : 0) }
      ret = {}
      hash.each do |k, v|
        return nil unless req_keys[k]
        req_keys[k] = 0
        ret.merge!(k => v)
      end
      # return nil if there is a required key not found
      unless req_keys.values.find { |x| x == 1 }
        ret
      end
    end

    module ComponentChoiceMixin
      def add_dependency!(ret, dep_cmp, base_cmp)
        ret[dep_cmp] ||= {
          'type'           => 'component',
          'search_pattern' => { ':filter' => [':eq', ':component_type', dep_cmp] },
          'description'    => "#{component_print_form(dep_cmp)} is required for #{component_print_form(base_cmp)}",
          'display_name'   => dep_cmp,
          'severity'       => 'warning'
        }
      end

      def component_order(input_hash)
        if after_cmps = input_hash['after']
          after_cmps.inject(ObjectModelForm::OutputHash.new) do |h, after_cmp|
            after_cmp_internal_form = convert_to_internal_cmp_form(after_cmp)
            el = { after_cmp_internal_form =>
              { 'after' => after_cmp_internal_form } }
            h.merge(el)
          end
        end
      end
    end

    class Component < self
      include ComponentChoiceMixin
      def initialize(module_name)
        @module_name = module_name
      end

      def convert(input_hash, context = {})
        (input_hash || {}).inject(OutputHash.new) { |h, (k, v)| h.merge(key(k) => body(v, k, context)) }
      end

      private

      def key(input_key)
         qualified_component(input_key)
      end

      def qualified_component(cmp)
        if @module_name == cmp
          cmp
        else
          "#{@module_name}#{ModCmpDelim}#{cmp}"
        end
      end

      def body(input_hash, cmp, _context = {})
        ret = OutputHash.new
        cmp_type = ret['display_name'] = ret['component_type'] = qualified_component(cmp)
        ret['basic_type'] = 'service'
        ret.set_if_not_nil('description', input_hash['description'])
        external_ref = external_ref(input_hash.req(:external_ref), cmp)
        ret['external_ref'] = external_ref
        ret.set_if_not_nil('only_one_per_node', only_one_per_node(external_ref))
        add_attributes!(ret, cmp_type, input_hash)
        opts = {}
        add_dependent_components!(ret, input_hash, cmp_type, opts)
        ret.set_if_not_nil('component_include_module', include_modules?(input_hash['include_modules']))
        if opts[:constants]
          add_attributes!(ret, cmp_type, ret_input_hash_with_constants(opts[:constants]), constant_attribute: true)
        end
        ret
      end

      def ret_input_hash_with_constants(constant_assigns)
        attrs_hash = constant_assigns.inject(InputHash.new) do |h, ca|
          el = { ca.attribute_name() => {
              'type' => ca.datatype() || 'string',
              'default' => ca.attribute_value()
            }.merge(Attribute::Constant.side_effect_settings())
          }
          h.merge(el)
        end
        InputHash.new('attributes' => attrs_hash)
      end

      def external_ref(input_hash, cmp)
        unless input_hash.is_a?(Hash) && input_hash.size == 1
          fail ParsingError.new('Component (?1) external_ref is ill-formed (?2)', cmp, input_hash)
        end
        type = input_hash.keys.first
        name_key =
          case type
            when 'puppet_class' then 'class_name'
            when 'puppet_definition' then 'definition_name'
            when 'serverspec_test' then 'test_name'
            else fail ParsingError.new('Component (?1) external_ref has illegal type (?2)', cmp, type)
          end
        name = input_hash.values.first
        OutputHash.new('type' => type, name_key => name)
      end

      def only_one_per_node(external_ref)
        external_ref['type'] != 'puppet_definition'
      end

      def include_modules?(incl_module_array, context = {})
        return nil if incl_module_array.nil?
        incl_module_array = [incl_module_array] if incl_module_array.is_a?(String)
        unless incl_module_array.is_a?(Array)
          err_params = ParsingError::Params.new(incl_module_array: incl_module_array, section: context[:section_name] || 'include_modules')
          err_msg = "The content in the '?section' section"
          if cmp_type = context[:component_type]
            cmp_name = component_print_form(cmp_type)
            err_params.merge!(component_name: cmp_name)
            err_msg += ' under component (?component_name)'
          end
          err_msg += ' is ill-formed: ?incl_module_array'
          fail ParsingError.new(err_msg, err_params)
        end
        ret = OutputHash.new
        incl_module_array.each do |incl_module|
          el =
            if incl_module.is_a?(String)
              { 'display_name' => incl_module }
            elsif incl_module.is_a?(Hash)
              hash = hash_contains?(incl_module, ['*module', 'version'])
              version_constraint = include_module_version_constraint(hash['version'])
              { 'display_name' => hash['module'], 'version_constraint' => version_constraint }
            end
          unless el
            fail ParsingError.new('The include_module element (?1) is ill-formed', incl_module)
          end
          ref = el['display_name']
          ret.merge!(ref => el)
        end
        ret
      end

      def combine_includes(more_specific_incls, less_specific_incls)
        if more_specific_incls.nil?
          less_specific_incls
        elsif less_specific_incls.nil?
          more_specific_incls
        else
          less_specific_incls.merge(more_specific_incls)
        end
      end

      IncludeModVersionOps = ['>=']
      IncludeModVersionNumRegexp = /^[0-9]+\.[0-9]+\.[0-9]+/
      def include_module_version_constraint(version)
        no_error =
          if version.is_a?(String)
            if version =~ IncludeModVersionNumRegexp
              true
            end
          elsif version.is_a?(Array)
            if version.size == 2 && IncludeModVersionOps.include?(version[0]) && version[1] =~ IncludeModVersionNumRegexp
              true
            end
          end
        unless no_error
          fail ParsingError.new('The include_modules version key (?1) is ill-formed', version)
        end
        version
      end

      def add_attributes!(ret, cmp_type, input_hash, opts = {})
        unless in_attrs = input_hash['attributes']
          return ret
        end

        ParsingError.raise_error_if_not(in_attrs, Hash)

        attrs = OutputHash.new
        in_attrs.each_pair do |name, info|
          if info.is_a?(Hash)
            attrs[name] = self.class::AttributeFields.attribute_fields(cmp_type, name, info, opts)
          else
            cmp_name = component_print_form(cmp_type)
            fail ParsingError.new('Ill-formed attributes section for component (?1): ?2', cmp_name, 'attributes' => in_attrs)
          end
        end

        if ret['attribute']
          ret['attribute'].merge!(attrs)
        else
          ret['attribute'] = attrs
        end
        ret
      end

      # partitions into link_defs, "dependency", and "component_order"
      def add_dependent_components!(ret, input_hash, base_cmp, opts = {})
        dep_config = get_dependent_config(input_hash, base_cmp, opts)
        ret.set_if_not_nil('dependency', dep_config[:dependencies])
        ret.set_if_not_nil('component_order', dep_config[:component_order])
        ret.set_if_not_nil('link_defs', dep_config[:link_defs])
      end

      def get_dependent_config(input_hash, base_cmp, opts = {})
        ret = {}
        link_defs  = []
        if in_dep_cmps = input_hash['depends_on']
          convert_to_hash_form(in_dep_cmps) do |conn_ref, conn_info|
            choices = choice().convert_choices(conn_ref, conn_info, base_cmp, opts)

            # determine if create a link def and/or a dependency
            # creaet a dependency if just single choice and base adn depnedncy on same node
            # TODO: only handling addition of dependencies if single choice; consider adding just temporal if multiple choices
            if choices.size == 1
              choice = choices.first
              if choice.is_internal?()
                pntr = ret[:dependencies] ||= OutputHash.new
                add_dependency!(pntr, choice.dependent_component(), base_cmp)
              end
            end

            # create link defs if there are multiple choices or theer are attribute mappings
            if choices.size > 1 || (choices.size == 1 && choices.first.has_attribute_mappings?())
              link_def = OutputHash.new(
                'type' => get_connection_label(conn_ref, conn_info),
                'required' =>  true, #will be putting optional elements under a key that is peer to 'depends_on'
                'possible_links' => choices.map(&:possible_link)
              )
              link_def.set_if_not_nil('description', conn_info['description'])
              link_defs << link_def
            end
          end
        end
        ret[:link_defs] = link_defs unless link_defs.empty?
        # TODO: is this redundant with 'order', which just added
        if component_order = component_order(input_hash)
          ret[:component_order] = component_order
        end
        ret
      end

      def get_connection_label(conn_ref, conn_info)
        # if component key given then conn_ref will be connection label
        # if there are choices then conn_ref will be connection label
        # otherwise conn_ref will be component ref and we use the component part for the conenction label
        if conn_info['component'] || conn_info['choices']
          conn_ref
        else
          cmp_external_form = conn_ref
          cmp_external_form
        end
      end
    end

    class Choice < self
      extend ComponentChoiceMixin

      def initialize
        @possible_link = OutputHash.new()
      end

      def self.convert_choices(conn_ref, conn_info_x, base_cmp, opts = {})
        conn_info =
          if conn_info_x.is_a?(Hash)
            conn_info_x
          elsif conn_info_x.is_a?(Array) && conn_info_x.size == 1 && conn_info_x.first.is_a?(Hash)
            conn_info_x.first
          else
            base_cmp_name = component_print_form(base_cmp)
            err_msg = 'The following dependency on component (?1) is ill-formed: ?2'
            fail ParsingError.new(err_msg, base_cmp_name, conn_ref => conn_info_x)
          end
        if choices = conn_info['choices']
          opts_choice = opts.merge(conn_ref: conn_ref)
          choices.map { |choice| convert_choice(choice, base_cmp, conn_info, opts_choice) }
        else
          dep_cmp_external_form = conn_info['component'] || conn_ref
          parent_info = {}
          [convert_choice(conn_info.merge('component' => dep_cmp_external_form), base_cmp, parent_info, opts)]
        end
      end

      attr_reader :possible_link

      def has_attribute_mappings?
        ams = dep_component_info()['attribute_mappings']
        not (ams.nil? || ams.empty?)
      end

      def is_internal?
        dep_component_info()['type'] == 'internal'
      end

      def dependent_component
        @possible_link.keys.first
      end

      def convert(dep_cmp_info, base_cmp, parent_info = {}, opts = {})
        unless dep_cmp_raw = dep_cmp_info['component'] || opts[:conn_ref]
          fail ParsingError.new('Dependency possible connection (?1) is missing component key', dep_cmp_info)
        end
        dep_cmp = convert_to_internal_cmp_form(dep_cmp_raw)
        ret_info = { 'type' => link_type(dep_cmp_info, parent_info, opts) }
        if order = order(dep_cmp_info)
          ret_info['order'] = order
        end
        in_attr_mappings = (dep_cmp_info['attribute_mappings'] || []) + (parent_info['attribute_mappings'] || [])
        unless in_attr_mappings.empty?
          ret_info['attribute_mappings'] = in_attr_mappings.map { |in_am| convert_attribute_mapping(in_am, base_cmp, dep_cmp, opts) }
        end
        @possible_link.merge!(convert_to_internal_cmp_form(dep_cmp) => ret_info)
        self
      end

      private

      def order(dep_cmp_info)
        if ret = dep_cmp_info['order']
          unless LegalOrderVals.include?(ret)
            fail ParsingError.new("Value of order param (?1) is ill-formed; it should be one of (#{LegalOrderVals}.join(', '))", ret)
          end
          ret
        end
      end
      LegalOrderVals = ['after', 'before']

      def self.convert_choice(dep_cmp_info, base_cmp, parent_info = {}, opts = {})
        new().convert(dep_cmp_info, base_cmp, parent_info, opts)
      end

      def dep_component_info
        @possible_link.values.first
      end

      DefaultLinkType = 'local'
      def link_type(link_info, parent_link_info = {}, opts = {})
        ret = nil
        loc = link_info['location'] || parent_link_info['location']
        if opts[:no_default_link_type] && loc.nil?
          return ret
        end
        loc ||= DefaultLinkType
        case loc
         when 'local' then 'internal'
         when 'remote' then 'external'
         else fail ParsingError.new('Ill-formed dependency location type (?1)', loc)
        end
      end

      def convert_attribute_mapping(input_am, base_cmp, dep_cmp, opts = {})
        # TODO: right now only treating constant on right hand side meaning only for <- case
        if input_am =~ /(^[^ ]+)[ ]*->[ ]*([^ ].*$)/
          dep_attr = Regexp.last_match(1)
          base_attr = Regexp.last_match(2)
          left = convert_attr_ref_simple(dep_attr, :dep, dep_cmp, :output)
          right = convert_attr_ref_simple(base_attr, :base, base_cmp, :input)
        elsif input_am =~ /(^[^ ]+)[ ]*<-[ ]*([^ ].*$)/
          dep_attr = Regexp.last_match(1)
          base_attr = Regexp.last_match(2)
          left = convert_attr_ref_base(base_attr, base_cmp, dep_attr, dep_cmp, :output, opts)
          right = convert_attr_ref_simple(dep_attr, :dep, dep_cmp, :input)
        else
          fail ParsingError.new('Attribute mapping (?1) is ill-formed', input_am)
        end
        { left => right }
      end
      public :convert_attribute_mapping

      def convert_attr_ref_simple(attr_ref, dep_or_base, cmp, input_or_output)
        if attr_ref =~ /(^[^.]+)\.([^.]+$)/
          if input_or_output == :input
            fail ParsingError.new('Attribute reference (?1) is ill-formed', attr_ref)
          end
          prefix = Regexp.last_match(1)
          attr = Regexp.last_match(2)
          case prefix
          when '$node' then (dep_or_base == :dep) ? 'remote_node' : 'local_node'
          else fail ParsingError.new('Attribute reference (?1) is ill-formed', attr_ref)
          end + ".#{attr.gsub(/host_address$/, 'host_addresses_ipv4.0')}"
        else
          has_dollar_sign = has_variable?(attr_ref)
          if (input_or_output == :input && has_dollar_sign) ||
              (input_or_output == :output && !has_dollar_sign)
            fail ParsingError.new('Attribute reference (?1) is ill-formed', attr_ref)
          end
          var_name = attr_ref
          # if dollar sign is first character and not embedded string than strip of dollar sign
          if var_name =~ /^\$[^\{]/
            var_name = var_name.gsub(/^\$/, '')
          end
          "#{convert_to_internal_cmp_form(cmp)}.#{var_name}"
        end
      end

      def convert_attr_ref_base(attr_ref, base_cmp, dep_attr_ref, dep_cmp, input_or_output, opts = {})
        is_constant?(attr_ref, base_cmp, dep_attr_ref, dep_cmp, opts) || convert_attr_ref_simple(attr_ref, :base, base_cmp, input_or_output)
      end

      def has_variable?(attr_ref)
        attr_ref =~ /\$/
      end

      def is_constant?(attr_ref, base_cmp, dep_attr_ref, dep_cmp, opts = {})
        return nil if has_variable?(attr_ref)

        datatype = :string
        const = nil
        if attr_ref =~ /^'(.+)'$/
          const = Regexp.last_match(1)
        elsif ['true', 'false'].include?(attr_ref)
          const = attr_ref
          datatype = :boolean
        elsif attr_ref =~ /^[0-9]+$/
          const = attr_ref
          datatype = :integer
        elsif sanitized_attr_ref = is_json_constant?(attr_ref)
          const = sanitized_attr_ref
          datatype = :json
        end
        unless constant_assign = (const && Attribute::Constant.create?(const, dep_attr_ref, dep_cmp, datatype))
          fail ParsingError.new('Attribute reference (?1) is ill-formed', attr_ref)
        end
        constants = opts[:constants] ||= []
        unless constant_assign.is_in?(constants)
          constants << constant_assign
        end
        "#{convert_to_internal_cmp_form(base_cmp)}.#{constant_assign.attribute_name()}"
      end

      # returns sanitized_attr_ref
      def is_json_constant?(attr_ref)
        # TODO: this is just temp hack in how whether it is detected; providing fro using ' rather than " in constant
        if attr_ref =~ /[{]/
          attr_ref.gsub(/'/, "\"")
        end
      end
    end
  end
end; end; end
