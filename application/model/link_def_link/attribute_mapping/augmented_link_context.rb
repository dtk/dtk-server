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
        num_ngs = [@input_attr[:node],@output_attr[:node]].inject(0){|r,n|r +(n.is_node_group? ? 1 : 0)}
        case num_ngs
          when 0 then nil
          when 1 then ret_links_with_node_group?()
          when 2 then raise ErrorUsage.new("Not treating links between components that are both on node groups")
        end 
      end

      # determine if this manifests as single of multiple links; if single link just pass nil
      # when this is called theer is one node group and one node
      def ret_links_with_node_group?()
        if @input_attr[:node].is_node_group?
          nil # to fallback to single link treatment
        else # @output_attr[:node].is_node_group?
          raise_error_if_array_on_node_group(@output_attr)
          # raise error if output_attr is node attributes and input is not an array
          
          raise Error.new("got here")
        end
      end

      def attribute_is_array?(attr)
        attr[:semantic_type_object].is_array?()
      end

      def raise_error_if_array_on_node_group(attr)
        if attribute_is_array?(attr)
          raise ErrorUsage.new("Not treating attribute mapping with an array attribute (#{attr_pp_form(attr)}) on anode group")
        end
      end

      def attr_pp_form(attr)
        ret =  attr.get_field?(:display_name)
        if cmp = attr[:component]
          ret = "#{cmp.get_field?(:display_name)}/#{ret}"
        end
        if node = attr[:node]
          ret = "#{node.get_field?(:display_name)}/#{ret}"
        end
        ret
      end
    end
  end
end; end

