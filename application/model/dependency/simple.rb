module DTK; class Dependency
  class Simple < All
    def initialize(dependency_obj)
      @dependency_obj = dependency_obj
    end

    def scalar_print_form?()
      if cmp_type = @dependency_obj.is_simple_component_type_match?()
        Component.component_type_print_form(cmp_type)
      end
    end

    def self.augment_component_instances!(cmp_instances)
      return cmp_instances if cmp_instances.empty?
      sp_hash = {
        :cols => [:id,:group_id,:component_component_id,:search_pattern,:type,:description,:severity],
        :filter => [:oneof,:component_component_id,cmp_instances.map{|cmp|cmp.id()}]
      }
      dep_mh = cmp_instances.first.model_handle(:dependency)

      deps = Model.get_objs(dep_mh,sp_hash)
      return cmp_instances if deps.empty?
      ndx_cmp_instances = cmp_instances.inject(Hash.new){|h,cmp|h.merge(cmp[:id] => cmp)}
      deps.each do |dep|
        cmp = ndx_cmp_instances[dep[:component_component_id]]
        (cmp[:dependencies] ||= Array.new) << new(dep)
      end
      cmp_instances
    end

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
  end
end; end
