module XYZ
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
        :description => "#{other_cmp[:dispaly_name]} #{type} #{cmp[:display_name]}",
        :search_pattern => search_pattern,
        :severity => "warning",
        :library_library_id => cmp[:library_library_id]
      }
      dep_mh = component_idh.createMH(:dependency)
      Model.create_from_row(dep_mh,create_row)
    end
  end
end


