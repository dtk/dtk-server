module DTK
  class NodeBindings
    class Target
      r8_nested_require('target','assembly_node')
      def self.parse(parse_input)
        ret = nil
        if parse_input.type?(String)
          input = parse_input.input
          if input.split('/').size == 3 and input =~ /^assembly\//
            ret = AssemblyNode.parse(parse_input)
          end 
        end
        ret || raise(parse_input.error("Node Target has illegal form: ?input"))
      end
    end
  end
end
