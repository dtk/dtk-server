module DTK; class Dependency
  class Link < All
    def initialize(link_def)
      super()
      @link_def = link_def
    end

    def self.create_dependency?(cmp_template,antec_cmp_template,opts={})
      antec_attr_pattern = opts[:antec_attr_pattern]
      dep_attr_pattern = opts[:dep_attr_pattern ]
      unless antec_attr_pattern and  dep_attr_pattern
        raise Error.new("Not implemented: when opts does not include :antec_attr_pattern and :dep_attr_pattern")
      end
      external_or_internal = (dep_attr_pattern.node().id() == antec_attr_pattern.node().id() ? "internal" : "external")
      if link_def_link = matching_link_def_link?(external_or_internal,cmp_template,antec_cmp_template)
        if attr_mapping = link_def_link.matching_attribute_mapping?(dep_attr_pattern,antec_attr_pattern)
          pp [:debug_match_found, attr_mapping]
          return 
        else
          link_def_link.add_attribute_mapping(dep_attr_pattern,antec_attr_pattern)
        end
      end
    end

    def depends_on_print_form?()
      #link_type may be label or component_type
      #TODO: assumption that its safe to process label through component_type_print_form
      Component.component_type_print_form(@link_def[:link_type])
    end

    def self.augment_component_instances!(assembly,components,opts=Opts.new)
      return components if components.empty?
      link_defs = LinkDef.get(components.map{|cmp|cmp.id_handle()})
      unless link_defs.empty?
        link_deps = Array.new
        components.each do |cmp|
          cmp_id = cmp[:id]
          matching_link_defs = link_defs.select{|ld|ld[:component_component_id] == cmp_id}            
          matching_link_defs.each do |ld|
            dep = new(ld)
            link_deps << dep
            (cmp[:dependencies] ||= Array.new) << dep
          end
        end
        if opts[:ret_statisfied_by] and not link_deps.empty?
          aug_port_links = assembly.get_augmented_port_links()
          link_deps.each{|link_dep|link_dep.set_satisfied_by_component_ids?(aug_port_links)}
        end
      end
      components
    end

    def set_satisfied_by_component_ids?(aug_port_links)
      link_def_id = @link_def[:id]
      matches = aug_port_links.select{|aug_port|aug_port[:input_port][:link_def_id] == link_def_id}
      @satisfied_by_component_ids = matches.map{|match|match[:output_port][:component_id]}
    end

   private
    def self.matching_link_def_link?(external_or_internal,cmp_template,antec_cmp_template)
      antec_cmp_type = antec_cmp_template.get_field?(:component_type)
      matches = cmp_template.get_link_def_links().select do |r|
        r[:remote_component_type] == antec_cmp_type and
          r[:type] == external_or_internal
      end
      if matches.size > 1
        raise Error.new("Not implemented when matching_link_def_link? finds more than 1 match")
      end
      matches.first
    end
  end
end; end

