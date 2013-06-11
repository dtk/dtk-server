module DTK; class Dependency
  class Link < All
    def initialize(link_def)
      @link_def = link_def
    end

    def scalar_print_form?()
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
          link_deps.each{|link_dep|link_dep.set_satisfied_by_component_id?(aug_port_links)}
        end
      end
      pp [:debug_link_deps,components.map{|r|r[:dependencies]}.compact]
      components
    end

    def set_satisfied_by_component_id?(aug_port_links)
      link_def_id = @link_def[:id]
      if match = aug_port_links.find{|aug_port|aug_port[:input_port][:link_def_id] == link_def_id}
        @satisfied_by_component_id = match[:output_port][:component_id]
      end 
    end

  end
end; end

