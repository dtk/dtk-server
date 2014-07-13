module DTK; class NodeBindings
  class Target
    class AssemblyNode < Hash
      def initialize(assembly_name,node_name)
        super()
        hash = {
          :assembly_name => assembly_name,
          :node_name => node_name
        }
        replace(hash)
      end
      def self.parse(parse_input)
        input = parse_input.input
        split = input.split('/')
        assembly_name = split[1]
        node_name = split[2]
        new(assembly_name,node_name)
      end
    end
  end
end; end
