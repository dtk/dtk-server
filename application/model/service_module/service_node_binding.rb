module DTK
  class ServiceNodeBinding < Model
    r8_nested_require('service_node_binding','import')
    def self.import_add_on_node_bindings(aug_assembly_nodes,node_bindings)
      Import.new(aug_assembly_nodes).import(node_bindings)
    end
  end
end
