module DTK
  class LinkDef::Context
    class NodeMappings < Hash
      def initialize(local,remote=nil)
        super()
        replace(local: local, remote: remote||local)
      end
      private :initialize

      def self.create_from_component_mappings(cmp_mappings)
        ndx_node_ids = cmp_mappings.inject({}){|h,(k,v)|h.merge(k => v[:node_node_id])}
        node_mh = cmp_mappings[:local].model_handle(:node)
        ndx_node_info = {}
        Node::TargetRef.get_ndx_linked_target_refs(node_mh,ndx_node_ids.values.uniq).each_pair do |_node_id,tr_info|
          node = tr_info.node
          ndx = node.id
          if node.is_node_group?
            node = ServiceNodeGroup::Cache.create_as(node,tr_info.target_refs) 
          else
            #switch to pointing to target ref if it exists
            unless tr_info.target_refs.empty?
              if tr_info.target_refs.size > 1
                Log.error("Unexpected that tr_info.target_refs.size > 1")
              end
              node = tr_info.target_refs.first
            end
          end
          ndx_node_info.merge!(ndx => node)
        end
        new(ndx_node_info[ndx_node_ids[:local]],ndx_node_info[ndx_node_ids[:remote]])
      end

      def is_internal?
        local[:id] == remote[:id]
      end

      def node_group_members
        ret = []
        if local.is_node_group?()
          ret << {endpoint: :local, nodes: local[:target_refs]}
        end
        if remote.is_node_group?()
          ret << {endpoint: :remote, nodes: remote[:target_refs]}
        end
        ret
      end

      def local
        self[:local]
      end

      def remote
        self[:remote]
      end
    end
  end
end
