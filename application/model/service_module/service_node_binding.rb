module DTK
  class ServiceNodeBinding < Model
    def self.import_add_on_node_bindings(library_idh,node_bindings)
      ret = Hash.new
      return ret if (node_bindings||[]).empty?
      #TODO: stub
      pp [:node_bindings,node_bindings]
      ret
    end
  end
end
