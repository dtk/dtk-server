module DTK; class Node; class TargetRef
  class Input 
    class BaseNodes < self
      def initialize(target,assembly,nodes)
        super()
        @target = target
        @assembly = assembly
        num_target_refs_needed(nodes).each{|node_info|add!(node_info)}
      end

      #This creates if needed target refs and links nodes to them
      #TODO: now creating new ones as opposed to case where overlaying asssembly on existing nodes
      def create_linked_target_refs?()
        target_ref_hash = ret_target_ref_hash()
        pp [:ret_target_ref_hash,target_ref_hash,self]
        raise ErrorUsage.new('got here')

        target_idh = target.id_handle()
        Model.import_objects_from_hash(target_idh, {:node => target_ref_hash}, :return_info => true)
      end

     private
      def add!(node_info)
        self << Element.new(node_info)
      end
      def ret_target_ref_hash()
        inject(Hash.new){|h,el|h.merge(el.ret_target_ref_hash(@target,@assembly))}
      end

      #returns for each node that needs one or more target refs the following hash
      # :node
      # :num_needed
      # :num_linked
      def num_target_refs_needed(nodes)
        ret = Array.new
        #TODO: temporary; removes all nodes that are not node groups
        nodes = nodes.select{|n|n.is_node_group?()}
        return ret if nodes.empty?
        ndx_linked_target_ref_idhs = ndx_linked_target_ref_idhs(nodes)
        nodes.each do |node|
          node_id = node[:id]
          num_linked = (ndx_linked_target_ref_idhs[node_id]||[]).size 
          num_needed = node.attribute.cardinality - num_linked
          if num_needed > 0
            ret << {:node => node,:num_needed => num_needed,:num_linked => num_linked}
          else num_needed < 0
            Log.error("Unexpected that number of target refs (#{num_linked}) for (#{node[:display_name].to_s}) is graeter than cardinaility (#{node.attribute.cardinality.to_s})")
          end
        end
        ret
      end

      #indexed by node id
      def ndx_linked_target_ref_idhs(nodes)
        ret = Hash.new
        Log.error("need to index by assembly")
        sp_hash = {
          :cols => [:id,:group_id,:display_name,:node_id,:node_group_id],
          :filter => [:and, 
                      [:oneof,:node_group_id,nodes.map{|n|n.id}],
                      [:eq,:datacenter_datacenter_id,@target.id]]
        }
        node_mh = @target.model_handle(:node)
        Model.get_objs(@target.model_handle(:node_group_relation),sp_hash).each do |r|
          (ret[r[:node_group_id]] ||= Array.new) << node_mh.createIDH(:id => r[:node_id])
        end
      end


      class Element 
        include ElementMixin
        def initialize(node_info)
          @node = node_info[:node]
          @num_needed = node_info[:num_needed]
          @num_linked = node_info[:num_linked]
          @type = :base_node_link
        end
        
        def ret_target_ref_hash(target,assembly)
          ret = Hash.new
          unless display_name = @node.get_field?(:display_name)
            raise Error.new("Unexpected that that node has no name field")
          end
          external_ref = @node.external_ref
          unless external_ref.references_image?(target)
            raise ErrorUsage.new("Node (#{display_name}) is not in target that supports node creation or does not have needed info")
          end
          (1..@num_needed).inject(Hash.new) do |h,index|
            hash = {
              :display_name => ret_display_name(display_name,:index => index,:assembly => assembly),
              :type => TargetRef.type(),
              :external_ref => external_ref.hash() 
            }          
            ref = ret_ref(display_name,:index => index,:assembly => assembly)
            h.merge(ref => hash)
          end
        end
      end
    end
  end
end; end; end
