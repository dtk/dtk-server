module DTK; class LinkDefLink
  class AttributeMapping
    class AugmentedLinkContext
      attr_reader :attribute_mapping,:input_attr,:input_path,:output_attr,:output_path
      def initialize(am,input_attr,input_path,output_attr,output_path)
        super()
        @attribute_mapping = am
        @input_attr = input_attr
        @input_path = input_path
        @output_attr = output_attr
        @output_path = output_path
      end

      # returns Array of AugmentedLink objects 
      def ret_links()
        ret_links_multiple_links_needed?() || [AugmentedLink.ret_link(self)]
      end

     private
      def ret_links_multiple_links_needed?()
        num_ngs = [@input_attr[:node],@output_attr[:node]].inject(0){|r,n|r +(!n.nil? and n.is_node_group? ? 1 : 0)}
        case num_ngs
          when 0 then nil
          when 1 then ret_links_with_node_group()
          when 2 then raise ErrorUsage.new("Not treating links between components that are both on node groups")
        end 
      end

      def ret_links_with_node_group()
        raise Error.new("got here")
      end

    end
  end
end; end

