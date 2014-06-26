module DTK; class Node
  class Filter
    def filter(nodes)
      filter_aux?(nodes)
    end
    def include?(node)
      !filter_aux?([node]).empty?
    end
    class NodeList < self
      def initialize(node_idhs)
        @node_ids = node_idhs.map{|n|n.get_id()} 
      end
      def filter_aux?(nodes)
        nodes.select{|n|@node_ids.include?(n[:id])}
      end
    end
  end
end; end
