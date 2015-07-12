module DTK; class Node
  class TargetRef
    # Clone has methods used when staging (cloning) taht involves target refs
    class Clone
      def initialize(target, assembly, nodes)
        @target = target
        @assembly = assembly
        @nodes = nodes
      end
      # this creates needed target refs and their links to them
      # there are a number of cases treated on a node by node basis (i.e., member of nodes)
      #  if node is a group then creating new target refs for it as function of its cardinality
      #  if node has been designated as matched to an existing target ref, need to create links to these
      #  otherwise returns a state change object in teh output array
      def create_target_refs_and_links?
        tr_create = [] #node/node-groups that need target ref created
        tr_link = {} #node/node-groups that need to be linked to existing target refs
        tr_link_candidates = []

        # ndx_needs_sc is used to find nodes that need a state change object
        # meaning model is annoatted so these when a task is run will cause a node to be created
        # initiallly set ndx_needs_state_change to have all nodes and then in loop below remove ones
        # that are linked to existing nodes
        ndx_needs_sc = {}
        @nodes.each do |node|
          if node.is_node_group?() && !node[:target_refs_exist]
            tr_create << node
          else
            tr_link_candidates << node
          end
          # initiallly set ndx_needs_state_change to have all nodes
          ndx_needs_sc.merge!(node[:id] => node)
        end

        Input::BaseNodes.create_linked_target_refs?(@target, @assembly, tr_create)

        to_link_array = existing_target_refs_to_link(tr_link_candidates, ndx_needs_sc)
        link_to_target_refs(to_link_array)

        # needed target_ref state changes
        ndx_needs_sc.reject { |_node, needs_sc| !needs_sc }.values
      end

      private

      ToLinkElement = Struct.new(:node_instance_id, :target_ref)
      # This method returns array of
      # and also updates ndx_needs_sc
      def existing_target_refs_to_link(tr_link_candidates, ndx_needs_sc)
        ret = []
        return ret if tr_link_candidates.empty?
        # See if nodes have target refs computed already; if so compute these
        # TODO: convert so that always case target refs computed already
        trs_that_need_processing = []
        tr_link_candidates.each do |node|
          trs = node[:target_refs_to_link] || []
          unless trs.empty?
            node_id = node[:id]
            ret += trs.map { |target_ref| ToLinkElement.new(node_id, target_ref) }
          else
            trs_that_need_processing << node
          end
        end

        return ret if trs_that_need_processing.empty?

        # TODO: after 'convert so that always case' can remove below
        ndx_node_template__node = trs_that_need_processing.inject({}) do |h, n|
          n[:node_template_id] ? h.merge!(n[:node_template_id] => n[:id]) : h
        end
        unless ndx_node_template__node.empty?
          sp_hash = {
            cols: [:id, :display_name, :type],
            filter: [:oneof, :id, ndx_node_template__node.keys]
          }
          Model.get_objs(@target.model_handle(:node), sp_hash).each do |nt|
            if nt.is_target_ref?()
              node_id = ndx_node_template__node[nt[:id]]
              ret << ToLinkElement.new(node_id, nt)
              ndx_needs_sc[node_id] = nil
            end
          end
        end
        ret
      end

      # This creates links between node instances and target refs
      # to_link_array is array of ToLinkElements
      def link_to_target_refs(to_link_array)
        return if to_link_array.empty?
        create_ngrs_objs_hash = to_link_array.inject({}) do |h, to_link_el|
          h.merge(Input::BaseNodes.target_ref_link_hash(to_link_el.node_instance_id, to_link_el.target_ref.id))
        end
        create_objs_hash = { node_group_relation: create_ngrs_objs_hash }
        Model.input_hash_content_into_model(@target.id_handle(), create_objs_hash)
      end
    end
  end
end; end
