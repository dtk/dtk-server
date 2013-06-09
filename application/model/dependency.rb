module DTK
  class Dependency < Model
    def self.add_component_dependency(component_idh, type, hash_info)
      #TODO: bug problem may be need to get parent of component to use craete rows
      #TODO: stubbed
#      cmp = component_idh.create_object.update_object!(:display_name,:library_library_id,:group_id)
      cmp = component_idh.create_object.update_object!(:display_name)
      other_cmp_idh = component_idh.createIDH(:id => hash_info[:other_component_id])
      other_cmp = other_cmp_idh.create_object.update_object!(:display_name,:component_type)
      search_pattern = {
        ":filter" => [":eq", ":component_type",other_cmp[:component_type]]
      }
      create_row = {
        :ref => other_cmp[:component_type],
        :component_component_id => component_idh.get_id(),
        :description => "#{other_cmp[:display_name]} #{type} #{cmp[:display_name]}",
        :search_pattern => search_pattern,
        :severity => "warning",
        :library_library_id => cmp[:library_library_id]
      }
      dep_mh = component_idh.createMH(:dependency)
      Model.create_from_row(dep_mh,create_row)
    end

    #assumption that this is called with components having keys :id,:dependencies, :extended_base, :component_type
    #this can be either component template or component instance with :dependencies joined in from associated template
    def self.find_ndx_derived_order(components)
      find_ndx_cmp_type_and_derived_order(components).inject(Hash.new){|h,(cmp_id,v)|h.merge(cmp_id => v[:component_dependencies])}
    end
    def self.find_ndx_cmp_type_and_derived_order(components)
      ret = Hash.new
      cmp_idhs = Array.new
      components.each do |cmp|
        unless pntr = ret[cmp[:id]]
          pntr = ret[cmp[:id]] = {:component_type => cmp[:component_type], :component_dependencies => Array.new}
          cmp_idhs << cmp.id_handle()
          end
        if cmp[:extended_base]
          pntr[:component_dependencies] << cmp[:extended_base]
        elsif deps = cmp[:dependencies]
          #process dependencies
          #TODO: hack until we have macros which will stamp the dependency to make this easier to detect
          #looking for signature where dependency has
          #:search_pattern=>{:filter=>[:and, [:eq, :component_type, <component_type>]
          filter = (deps[:search_pattern]||{})[":filter".to_sym]
          if filter and deps[:type] == "component"
            if filter[0] == ":eq" and filter[1] == ":component_type"
              pntr[:component_dependencies] << filter[2]
            end
          end
        end
      end
      ret
    end

  end
end


