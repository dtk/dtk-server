module Ramaze::Helper
  module Ports
    include XYZ
    def get_external_ports_under_datacenter(datacenter_id)
      filter = [:and,[:eq,:is_port,true],[:eq,:port_is_external,true]]
      cols = [:id,:display_name,:attribute_value,:port_type,:semantic_type,:semantic_type_summary]
      vcol_that_adds_parents = [:base_object_node_datacenter]
      field_set = Model::FieldSet.new(:attribute,cols+vcol_that_adds_parents)
      ds = SearchObject.create_from_field_set(field_set,ret_session_context_id(),filter).create_dataset()
      ds = ds.where(:param_datacenter_id => datacenter_id.to_i) if datacenter_id
      ds.all
    end
  end
end
