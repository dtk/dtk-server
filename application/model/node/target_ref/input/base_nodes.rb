module DTK; class Node; class TargetRef
  class Input 
    class BaseNodes < self
      def initialize(target,assembly)
        super()
        @target = target
        @assembly = assembly
      end
      def add!(node_info)
        self << Element.new(node_info)
      end

      def ret_target_ref_hash()
        inject(Hash.new){|h,el|h.merge(el.ret_target_ref_hash(@target,@assembly))}
      end

      class Element 
        include ElementMixin
        def initialize(node_info)
          @node = node_info[:node]
          @num_needed = node_info[:num_needed]
          @num_linked = node_info[:num_linked]
          @type = :base_node_link
        end
        
        #TODO: just copied from inventory; must change
        def ret_target_ref_hash(target,assembly)
          ret = Hash.new
          unless display_name = @node.get_field?(:display_name)
            raise Error.new("Unexpected that that node has no name field")
          end
          external_ref = @node.external_ref
          unless external_ref.references_image?(target)
            raise ErrorUsage.new("Node (#{display_name}) is not in target taht supports node creation or does not have needed info")
          end
          ret = (1..@num_needed).inject(Hash.new) do |h,num|
            index = num + @num_linked
            hash = {
              :display_name => ret_display_name(display_name,:index => index,:assembly => assembly),
              :type => TargetRef.type(),
              :external_ref => external_ref.hash() 
            }          
            ref = ret_ref(display_name,:index => index,:assembly => assembly)
            h.merge(ref => hash)
          end
          pp [:ret_target_ref_hash,ret,self]
          raise ErrorUsage.new('got here')
        end
      end
    end
  end
end; end; end
