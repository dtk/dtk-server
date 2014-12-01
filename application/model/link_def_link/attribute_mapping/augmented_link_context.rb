module DTK; class LinkDefLink
  class AttributeMapping
    class AugmentedLinkContext
      attr_reader :attribute_mapping,:input_path,:output_path
      def initialize(am,input_attr_obj,input_path,output_attr_obj,output_path)
        super()
        @attribute_mapping = am
        @input_attr_obj = input_attr_obj
        @input_path = input_path
        @output_attr_obj = output_attr_obj
        @output_path = output_path
      end
      def input_attr()
        @input_attr_obj.value()
      end
      def output_attr()
        @output_attr_obj.value()
      end

      # returns Array of AugmentedLink objects 
      def ret_links()
        ret_links_multiple_links_needed?() || [AugmentedLink.ret_link(self)]
      end

     private
      def ret_links_multiple_links_needed?()
        num_ngs = [@input_attr_obj.node,@output_attr_obj.node].inject(0){|r,n|r +(n.is_node_group? ? 1 : 0)}
        case num_ngs
          when 0 then nil
          when 1 then ret_links_with_node_group?()
          when 2 then raise ErrorUsage.new("Not treating links between components that are both on node groups")
        end 
      end

      # determine if this manifests as single of multiple links; if single link just pass nil
      # when this is called theer is one node group and one node
      def ret_links_with_node_group?()
        if @input_attr_obj.on_node_group?()
          nil # to fallback to single link treatment
        else # @output_attr_obj.ON_node_group?
          # raise error if array on node group
          #TODO: wrong check; see if there is apath and if so then see .. 
          if @output_attr_obj.is_array?()
            raise ErrorUsage.new("Not treating attribute mappings from an array attribute on a node group (#{@output_attr_obj.pp_form()})")
          end
          if @output_attr_obj.kind_of?(LinkDefContext::Value::NodeAttribute) and !input_attr_obj.is_array?()
            raise ErrorUsage.new("Node attributes on node groups (#{@output_attr_obj.pp_form()}) must connect to an array attribute, not '#{@inpput_attr_obj.pp_form()}'")
          end          
          #TODO: stub
          nil
        end
      end
    end
  end
end; end

