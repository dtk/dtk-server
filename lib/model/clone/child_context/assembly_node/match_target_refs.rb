module DTK; class ChildContext
  class AssemblyNode
    class MatchTargetRefs
      def initialize(parent)
        @parent = parent
      end

      def matching_strategy(target,stub_nodes)
        #TODO: stub
        :match_tags
      end

      def match_tags(target,stub_nodes,assembly_template_idh)
        ret = Array.new
        target_refs = Node::TargetRef.get_managed_nodes(target)
        ndx_tag_tr = Hash.new
        target_refs.each do |tr|
          (tr[:tags]||[]).each do |tag|
            (ndx_tag_tr[tag] ||= Array.new) << tr
          end
        end
        ndx_tag_stub_node = Hash.new
        stub_nodes.each do |stub_node|
          tag = stub_node[:display_name]
          if tr_match = ndx_tag_tr[tag]
            ndx_tag_stub_node[tag] = stub_node
          else
            raise ErrorUsage.new("There is no node in inventory with tag (#{tag})")
          end
        end
        ndx_tag_stub_node.inject(Array.new) do |ret,(tag,stub_node)|
          ret + assign_by_group(stub_node,ndx_tag_tr[tag],:tag => tag)
        end
      end

      def find_free_nodes(target,stub_nodes,assembly_template_idh)
        ret = Array.new
        free_nodes = Node::TargetRef.get_free_nodes(target)
        # assuming the free nodes are interchangable; pick one for each match
        num_free = free_nodes.size
        if stub_nodes.find{|n|n.is_node_group?()}
          raise Error.new("Not implemented: looking for free nodes with a node group")
        end
        num_needed = stub_nodes.size
        if num_free < num_needed
          raise_error_need_more_nodes(num_free,num_needed)
        end
        stub_nodes.each_with_index do |stub_node,i|
          target_ref = free_nodes[i]
          ret << hash_el(stub_node,target_ref)
        end
        ret
      end
      
      private
      def assign_by_group(stub_node,target_refs,context={})
        ret = Array.new
        is_node_group = stub_node.is_node_group?()
        num_free = target_refs.size
        num_needed = (is_node_group ? 
                      stub_node.attribute.cardinality(:no_default=>true)||num_free :
                      1)
        if num_free < num_needed
          raise_error_need_more_nodes(num_free,num_needed)
        end

        #sorting as heuristic to pick the needed target refs using when created as captured by id
        needed_trs = 
          if is_node_group
            target_refs.sort{|a,b|a[:id] <=> b[:id]}[0...num_needed]
          else
            target_refs
          end
        hash_els(stub_node,needed_trs)
      end

      private
      def raise_error_need_more_nodes(num_free,num_needed)
        num  = (num_needed == 1 ? '1 free node is' : "#{num_needed} free nodes are")
        free = (num_free == 1 ? '1 is' : "#{num_free} are")
        raise ErrorUsage.new("Cannot stage the assembly template because #{num} needed, but just #{free} available")
      end

      def hash_els(stub_node,target_refs)
        # mapping to just one target ref, but passing all as a key :target_refs_to_link
        sample_target_ref = target_refs.first
        [hash_el(stub_node,sample_target_ref,:target_refs_to_link => target_refs)]
      end

      def hash_el(stub_node,target_ref,extra_fields={})
        @parent.hash_el_when_match(stub_node,target_ref,{:target_refs_exist => true}.merge(extra_fields))
      end
    end
  end
end; end
