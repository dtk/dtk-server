module DTK; class Dependency
  class Link < All
    attr_reader :link_def
    def initialize(link_def)
      super()
      @link_def = link_def
    end

    def self.create_dependency?(cmp_template,antec_cmp_template,opts={})
      result = Hash.new
      source_attr_pattern = opts[:source_attr_pattern]
      target_attr_pattern = opts[:target_attr_pattern ]
      unless source_attr_pattern and  target_attr_pattern
        raise Error.new("Not implemented: when opts does not include :source_attr_pattern and :target_attr_pattern")
      end
      external_or_internal = (target_attr_pattern.node().id() == source_attr_pattern.node().id() ? "internal" : "external")
      aug_link_defs = cmp_template.get_augmented_link_defs()
      if link_def_link = matching_link_def_link?(aug_link_defs,external_or_internal,antec_cmp_template)
        unless link_def_link.matching_attribute_mapping?(target_attr_pattern,source_attr_pattern)
          # aug_link_defs gets updated as side effect
          link_def_link.add_attribute_mapping!(attribute_mapping_serialized_form(source_attr_pattern,target_attr_pattern))
          incrementally_update_component_dsl?(cmp_template,aug_link_defs,opts)
          result.merge!(:component_module_updated => true)
        end
      else
        link_def_create_hash = create_link_def_and_link(external_or_internal,cmp_template,antec_cmp_template,attribute_mapping_serialized_form(source_attr_pattern,target_attr_pattern))
        aug_link_defs = cmp_template.get_augmented_link_defs()
        incrementally_update_component_dsl?(cmp_template,aug_link_defs,opts)
        result.merge!(:component_module_updated => true, :link_def_created => {:hash_form => link_def_create_hash})
      end
      result
    end

    def depends_on_print_form?()
      # link_type may be label or component_type
      # TODO: assumption that its safe to process label through component_type_print_form
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

    def satisfied_by_component_ids
      @satisfied_by_component_ids
    end

   private
    def self.attribute_mapping_serialized_form(source_attr_pattern,target_attr_pattern)
      {source_attr_pattern.am_serialized_form() => target_attr_pattern.am_serialized_form()}
    end

    def self.matching_link_def_link?(aug_link_defs,external_or_internal,antec_cmp_template)
      antec_cmp_type = antec_cmp_template.get_field?(:component_type)
      matches = Array.new
      aug_link_defs.each  do |link_def|
        (link_def[:link_def_links]||[]).each do |link|
          if link[:remote_component_type] == antec_cmp_type and link [:type] == external_or_internal
            matches << link
          end
        end
      end
      if matches.size > 1
        raise Error.new("Not implemented when matching_augmented_link_def? finds more than 1 match")
      end
      matches.first
    end
    
    def self.create_link_def_and_link(external_or_internal,cmp_template,antec_cmp_template,am_serialized_form)
      antec_cmp_type = antec_cmp_template[:component_type]
      serialized_link_def =  
        {"type" => antec_cmp_template.display_name_print_form(),
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
      link_def_create_hash
    end

    def self.incrementally_update_component_dsl?(cmp_template,aug_link_defs,opts={})
      if update_dsl = opts[:update_dsl]
        unless module_branch = update_dsl[:module_branch]
          raise Error.new("If update_dsl is specified then module_branch must be provided")
        end
        module_branch.incrementally_update_component_dsl(aug_link_defs,:component_template=>cmp_template)
      end
    end
  end
end; end

