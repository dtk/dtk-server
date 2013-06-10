module DTK; class Dependency
  class Link < All
    def self.augment_component_instances!(components)
      return components if components.empty?
      link_defs = LinkDef.get(components.map{|cmp|cmp.id_handle()})
      unless link_defs.empty?
        components.each do |cmp|
          cmp_id = cmp[:id]
          matching_link_defs = link_defs.select{|ld|ld[:component_component_id] == cmp_id}            
          matching_link_defs.each{|ld|(cmp[:dependencies] ||= Array.new) << new(ld)}
        end
      end
      components
    end
  end
end; end

