module DTK; class Assembly; class Instance; module Get
  module AttributeMixin
    def get_attributes_print_form(opts={})
      if filter = opts[:filter]
        case filter
          when :required_unset_attributes
            opts.merge!(filter_proc: FilterProc)
          else
            raise Error.new("not treating filter (#{filter}) in Assembly::Instance#get_attributes_print_form")
        end
      end
      get_attributes_print_form_aux(opts)
    end
    FilterProc = lambda do |r|
      attr =
        if r.is_a?(Attribute) then r
        elsif r[:attribute] then r[:attribute]
        else raise Error.new("Unexpected form for filtered element (#{r.inspect})")
        end
      attr.required_unset_attribute?()
    end

    def get_attributes_all_levels
      assembly_attrs = get_assembly_level_attributes()
      component_attrs = get_augmented_nested_component_attributes()
      node_attrs = get_augmented_node_attributes()
      assembly_attrs + component_attrs + node_attrs
    end

    AttributesAllLevels = Struct.new(:assembly_attrs,:component_attrs,:node_attrs)
    def get_attributes_all_levels_struct(filter_proc=nil)
      assembly_attrs = get_assembly_level_attributes(filter_proc)
      component_atttrs = get_augmented_nested_component_attributes(filter_proc).reject do |attr|
        (not attr[:nested_component].get_field?(:only_one_per_node)) && attr.is_title_attribute?()
      end
      node_attrs = get_augmented_node_attributes(filter_proc)
      AttributesAllLevels.new(assembly_attrs,component_atttrs,node_attrs)
    end

    def get_augmented_nested_component_attributes(filter_proc=nil)
      get_objs_helper(:instance_nested_component_attributes,:attribute,filter_proc: filter_proc,augmented: true)
    end

    def get_augmented_node_attributes(filter_proc=nil)
      get_objs_helper(:node_attributes,:attribute,filter_proc: filter_proc,augmented: true)
    end

    private

    def get_attributes_print_form_aux(opts=Opts.new)
      filter_proc = opts[:filter_proc]
      all_attrs = get_attributes_all_levels_struct(filter_proc)

      # remove all assembly_wide_node attributes
      all_attrs.node_attrs.reject!{|r| r[:node] && r[:node][:type].eql?('assembly_wide')}

      filter_proc = opts[:filter_proc]
      assembly_attrs = all_attrs.assembly_attrs.map do |attr|
        attr.print_form(opts.merge(level: :assembly))
      end

      opts_attr = opts.merge(level: :component,assembly: self)
      component_attrs = Attribute.print_form(all_attrs.component_attrs,opts_attr)

      node_attrs = all_attrs.node_attrs.map do |aug_attr|
        aug_attr.print_form(opts.merge(level: :node))
      end
      (assembly_attrs + node_attrs + component_attrs).sort{|a,b|a[:display_name] <=> b[:display_name]}
    end
  end
end; end; end; end
