module DTK; class Node
  class TargetRef
    # Clone has methods used when staging (cloning) taht involves target refs
    class Clone
      def initialize(target,assembly,nodes)
        @target = target
        @assembly = assembly
        @nodes = nodes
      end
      # this creates needed target refs and their links to them
      # there are a number of cases treated on a node by node basis (i.e., member of nodes)
      #  if node is a group then creating new target refs for it as function of its cardinality
      #  if node has been designated as matched to an existing target ref, need to create links to these
      #  otherwise returns a state change object in teh output array
      def create_target_refs_and_links?()
        tr_create = Array.new #node/node-groups that need target ref created
        tr_link = Hash.new #node/node-groups that need to be linked to existing target refs
        tr_link_candidates = Array.new

        # ndx_needs_sc is used to find nodes that need a state change object
        # meaning model is annoatted so these when a task is run will cause a node to be created
        # initiallly set ndx_needs_state_change to have all nodes and then in loop below remove ones 
        # that are linked to existing nodes
        ndx_needs_sc = Hash.new
        @nodes.each do |node|
          if node.is_node_group?() and !node[:target_refs_exist]
            tr_create << node
          else
            tr_link_candidates << node
          end
          # initiallly set ndx_needs_state_change to have all nodes
          ndx_needs_sc.merge!(node[:id] => node)
        end

        unless tr_create.empty?
          Input::BaseNodes.create_linked_target_refs?(@target,@assembly,tr_create)
        end

        tr_link = existing_target_refs_to_link(tr_link_candidates,ndx_needs_sc)
        unless tr_link.empty?
          Input::BaseNodes.link_to_target_refs(@target,tr_link)
        end

        # needed target_ref state changes
        ndx_needs_sc.reject{|node,needs_sc|!needs_sc}.values
      end

     private
      # This method also updates ndx_needs_sc
      def existing_target_refs_to_link(tr_link_candidates,ndx_needs_sc)
        ret = Hash.new
        return ret if tr_link_candidates.empty?
        # See if nodes have target refs computed already; if so compute these
        # TODO: convert so that always case target refs computed already
        trs_that_need_processing = Array.new
        tr_link_candidates.each do |node|
          trs = node[:target_refs_to_link]||[]
          unless trs.empty?
            node_id = node[:id]
            trs.each{|target_ref|ret.merge!(node_id => target_ref)}
          else
            trs_that_need_processing << node
          end
        end

        return ret if trs_that_need_processing.empty?

        # TODO: after 'convert so that always case' can remove below 
        ndx_node_template__node = trs_that_need_processing.inject(Hash.new) do |h,n|
          n[:node_template_id] ? h.merge!(n[:node_template_id] => n[:id]) : h
        end
        unless ndx_node_template__node.empty?
          sp_hash = {
            :cols => [:id,:display_name,:type],
            :filter => [:oneof,:id,ndx_node_template__node.keys]
          }
          Model.get_objs(@target.model_handle(:node),sp_hash).each do |nt|
            if nt.is_target_ref?()
              node_id = ndx_node_template__node[nt[:id]]
              ret.merge!(node_id => nt)
              ndx_needs_sc[node_id] = nil
            end
          end
        end 
        ret
      end
    end
  end
end; end
