#TODO: put this in def
module DTK; class Node
  class NodeAttribute
    class CanonicalName < String
      class PuppetVersion < self
        def initialize()
          super('node_agent.puppet.version')
        end
      end
      class RootDeviceSize < self
        def initialize()
          super('storage.root_device_size')
        end
      end
       Names =
          [
           'node_group.cardinality',
           'node_group.cardinality_max',
           'node_agent.puppet.version',

          ].map{|n|self.new(n)} +
        [PuppetVersion.new,RootDeviceSize.new]
    end
  end
end; end
