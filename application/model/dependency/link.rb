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
          pp [:debug_link_deps,link_deps]
          aug_port_links = assembly.get_augmented_port_links()
          pp [:get_augmented_port_links,aug_port_links]
        end
      end
      components
    end
  end
end; end

