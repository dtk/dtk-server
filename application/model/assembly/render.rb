#renders an asembly isnatnce or templaet in serialized form
module XYZ
  module AssemblyRender
    def render(opts={})
      nested_objs = get_nested_objects_for_render()
      pp nested_objs
    end
   private
    def get_nested_objects_for_render()
      ndx_nodes = Hash.new
      sp_hash = {:cols => [:nested_nodes_and_cmps_for_render]}
      node_col_rows = get_objs(sp_hash)
      node_col_rows.each do |r|
        n = r[:node]
        node = ndx_nodes[n[:id]] ||= n.merge(:components => Array.new)
        node[:components] << r[:nested_component]
      end

      nested_node_ids = ndx_nodes.keys
      sp_hash = {
        :cols => Port.common_columns(),
        :filter => [:oneof, :node_node_id, nested_node_ids]
      }
      port_rows = Model.get_objs(model_handle(:port),sp_hash)
      port_rows.each do |r|
        node = ndx_nodes[r[:node_node_id]]
        (node[:ports] ||= Array.new) << r
      end
      sp_hash = {
        :cols => PortLink.common_columns(),
        :filter => [:eq, :assembly_id, id()]
      }
      port_links = Model.get_objs(model_handle(:port_link),sp_hash)
      port_links.each{|pl|pl.materialize!(PortLink.common_columns())}

      attr_cols = [:id,:display_name,:data_type,:attribute_value]
      sp_hash = {
        :cols => attr_cols,
        :filter => [:eq, :component_component_id, id()]
      }
      assembly_attrs = Model.get_objs(model_handle(:attribute),sp_hash)
      assembly_attrs.each{|attr|attr.materialize!(attr_cols)}

      {:nodes => ndx_nodes.values, :port_links => port_links, :attributes => assembly_attrs}
    end

  end
end
