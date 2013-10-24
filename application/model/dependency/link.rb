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
      aug_link_defs = cmp_template.get_augmented_link_defs()
      if link_def_link = matching_link_def_link?(aug_link_defs,external_or_internal,antec_cmp_template)
        unless link_def_link.matching_attribute_mapping?(dep_attr_pattern,antec_attr_pattern)
          #aug_link_defs get updated as side effect
          pp [:pre, aug_link_defs]
          link_def_link.add_attribute_mapping!(attribute_mapping_serialized_form(antec_attr_pattern,dep_attr_pattern))
          pp [:post, aug_link_defs]
        end
      else
        create_link_def_and_link(external_or_internal,cmp_template,antec_cmp_template,attribute_mapping_serialized_form(antec_attr_pattern,dep_attr_pattern))
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
    def self.attribute_mapping_serialized_form(antec_attr_pattern,dep_attr_pattern)
      {antec_attr_pattern.am_serialized_form() => dep_attr_pattern.am_serialized_form()}
    end

    def self.matching_link_def_link?(aug_link_defs,external_or_internal,antec_cmp_template)
      ret = nil
      antec_cmp_type = antec_cmp_template.get_field?(:component_type)
      if aug_link_defs.empty?
        return ret
      end
      matches = aug_link_defs.map{|r|r[:link_def_links]||[]}.flatten(1).select do |link|
        link[:remote_component_type] == antec_cmp_type and link [:type] == external_or_internal
      end
      if matches.size > 1
        raise Error.new("Not implemented when matching_augmented_link_def? finds more than 1 match")
      end
      matches.first
    end
    
    def self.create_link_def_and_link(external_or_internal,cmp_template,antec_cmp_template,am_serialized_form)
      antec_cmp_type = antec_cmp_template[:component_type]
      serialized_link_def =  
        {"type" => antec_cmp_type.split('__').last,
        "required"=>true,
        "possible_links"=>
        [{antec_cmp_type=>
           {"type"=>external_or_internal.to_s,
             "attribute_mappings"=> [am_serialized_form]
           }
         }]
      }
      link_def_create_hash = LinkDef.parse_from_create_dependency(serialized_link_def)
      Model.input_hash_content_into_model(cmp_template.id_handle(),:link_def => link_def_create_hash)
    end
  end
end; end

