module DTK
  class NodeBindings
    class NodeTarget
      r8_nested_require('node_target','assembly_node')

      attr_reader :type
      def initialize(type)
        @type = type
      end
      
      def self.parse_and_reify(parse_input)
        ret = nil
        if assembly_node = AssemblyNode.parse_and_reify(parse_input, :donot_raise_error => true)
          ret = assembly_node
        end
        ret || raise(parse_input.error("Node Target has illegal form: ?input"))
      end
    end
  end
end
