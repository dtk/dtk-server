module DTK
  class NodeBindings
    class NodeTarget
      r8_nested_require('node_target','assembly_node')
      def self.parse_and_reify(parse_input)
        ret = nil
        if AssemblyNode.class_of?(parse_input)
          ret = AssemblyNode.parse_and_reify(parse_input)
        end
        ret || raise(parse_input.error("Node Target has illegal form: ?input"))
      end
    end
  end
end
