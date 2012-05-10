#renders an asembly isnatnce or templaet in serialized form
module XYZ
  module AssemblyRender
    def render(opts={})
      nested_objs = get_node_assembly_nested_objects()
      pp nested_objs
    end
  end
end
