module DTK
  class NodeBindings
    class NodeTarget
      r8_nested_require('node_target','assembly_node')
      r8_nested_require('node_target','image')

      attr_reader :type
      def initialize(type)
        @type = type
      end
      
      def self.parse_and_reify(parse_input)
        AssemblyNode.parse_and_reify(parse_input, :donot_raise_error => true) ||
        Image.parse_and_reify(parse_input, :donot_raise_error => true) ||
        raise(parse_input.error("Node Target has illegal form: ?input"))
      end

      def match_or_create_node?(target)
        :match
      end
    end
  end
end
