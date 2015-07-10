module DTK
  class Target
    module Clone
      module SpecialNodeAttributes
        def self.process!(nodes)
          process_name_attribute!(nodes)
          process_cardinality_attribute!(nodes)
        end

        private

        def self.process_name_attribute!(nodes)
          constant_attr_fields = { hidden: true }
          nodes.each do |n|
            name = n.get_field?(:display_name)
            Node::NodeAttribute.create_or_set_attributes?([n], :name, name, constant_attr_fields)
          end
        end

        def self.process_cardinality_attribute!(nodes)
          # first set cardinality on node groups
          ndx_cardinality = {}
          nodes.each do |n|
            if n.is_node_group?()
              if card =  n[:target_refs_to_link] && n[:target_refs_to_link].size
                (ndx_cardinality[card] ||= []) << n
              end
            end
          end
          ndx_cardinality.each_pair do |card, nodes_to_set_card|
            Node::NodeAttribute.create_or_set_attributes?(nodes_to_set_card, :cardinality, card)
          end
          Node.cache_attribute_values!(nodes, :cardinality)
        end
      end
    end
  end
end
