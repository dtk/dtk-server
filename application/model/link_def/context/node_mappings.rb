module DTK
  class LinkDefContext
    class NodeMappings < Hash
      def self.create_from_cmp_mappings(cmp_mappings)
        ndx_node_ids = cmp_mappings.inject({}){|h,(k,v)|h.merge(k => v[:node_node_id])}
        sample_cmp = cmp_mappings[:local]
        node_mh = sample_cmp.model_handle(:node)
        if ndx_node_ids[:local] == ndx_node_ids[:remote] #shortcut if internal
          # since same node on both sides; just create from one of them
          node = node_mh.createIDH(:id => ndx_node_ids[:local]).create_object()
          new(node)
        else
          node_ng_info = Node.get_node_or_ng_summary(node_mh,ndx_node_ids.values)
          new(node_ng_info[ndx_node_ids[:local]],node_ng_info[ndx_node_ids[:remote]])
        end
      end
      
      def num_node_groups()
        values.inject(0){|s,n|n.is_node_group? ? s+1 : s}
      end
      def is_internal?()
        local[:id] == remote[:id]
      end
      def node_group_members()
        ret = Array.new
        if local.is_node_group?()
          ret << {:endpoint => :local, :nodes => local[:node_group_members]}
        end
        if remote.is_node_group?()
          ret << {:endpoint => :remote, :nodes => remote[:node_group_members]}
        end
        ret
      end
      def local()
        self[:local]
      end
      def remote()
        self[:remote]
      end
     private
      def initialize(local,remote=nil)
        super()
        replace(:local => local, :remote => remote||local)
      end
    end
  end
end
