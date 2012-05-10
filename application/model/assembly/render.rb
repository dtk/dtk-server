#renders an asembly isnatnce or templaet in serialized form
module XYZ
  module AssemblyRender
    def render(opts={})
      nested_objs = get_nested_objects_for_render()
      pp nested_objs
    end
   private
    def get_nested_objects_for_render()
      #get assembly level attributes
      sp_hash = {
        :cols => [:id,:display_name,:data_type,:value_asserted],
        :filter => [:eq, :component_component_id, id()]
      }
      assembly_attrs = Model.get_objs(model_handle(:attribute),sp_hash)

      #get nodes, components and implementations
      ndx_nodes = Hash.new
      ndx_impls = Hash.new
      sp_hash = {:cols => [:nested_nodes_and_cmps_for_render]}
      get_objs(sp_hash).each do |r|
        node = r[:node]
        node = ndx_nodes[node[:id]] ||= node.merge(:components => Array.new)
        cmp = r[:nested_component]
        node[:components] << cmp
        ndx_impls[cmp[:implementation_id]] ||= r[:implementation]
      end

      #get ports
      nested_node_ids = ndx_nodes.keys
      sp_hash = {
        :cols => [:id,:display_name,:type,:direction,:node_node_id],
        :filter => [:oneof, :node_node_id, nested_node_ids]
      }
      port_rows = Model.get_objs(model_handle(:port),sp_hash)
      port_rows.each do |r|
        node = ndx_nodes[r[:node_node_id]]
        (node[:ports] ||= Array.new) << r
      end

      #get port links
      sp_hash = {
        :cols => PortLink.common_columns(),
        :filter => [:eq, :assembly_id, id()]
      }
      port_links = Model.get_objs(model_handle(:port_link),sp_hash)

      {:nodes => ndx_nodes.values, :port_links => port_links, :attributes => assembly_attrs, :implementations => ndx_impls.values}
    end

  end
end
