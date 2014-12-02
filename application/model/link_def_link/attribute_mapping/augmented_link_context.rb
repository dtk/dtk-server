module DTK; class LinkDefLink
  class AttributeMapping
    class AugmentedLinkContext
      attr_reader :attribute_mapping,:input_path,:output_path
      def initialize(attribute_mapping,link_def_context,attr_and_path_info)
        @attribute_mapping = attribute_mapping
        @link_def_context = link_def_context
        info = attr_and_path_info # for succinctness
        @input_attr_obj = info[:input_attr_obj]
        @input_path = info[:input_path]
        @output_attr_obj = info[:output_attr_obj]
        @output_path = info[:output_path]
      end
      def input_attr()
        @input_attr_obj.value()
      end
      def output_attr()
        @output_attr_obj.value()
      end

      # returns Array of AugmentedLink objects 
      def ret_links()
        ret_links_multiple_links_needed?() || [ret_single_link(input_attr(),output_attr())]
      end

     private
      def ret_single_link(input_attr,output_attr)
        AugmentedLink.ret_link(@attribute_mapping,input_attr,@input_path,output_attr,@output_path)
      end

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
        else # @output_attr_obj.On_node_group?
          if @output_attr_obj.is_array?() and @output_path.nil?
          # raise error if array (not being indexed to be a scalar) on node group 
            raise ErrorUsage.new("Not treating attribute mappings from an array attribute on a node group (#{@output_attr_obj.pp_form()})")
          end
          if @output_attr_obj.is_node_attribute?() and !@input_attr_obj.is_array?()
            raise ErrorUsage.new("Node attributes on node groups (#{@output_attr_obj.pp_form()}) must connect to an array attribute, not '#{@input_attr_obj.pp_form()}'")
          end          
          ret_links_with_output_node_group()
        end
      end

      def ret_links_with_output_node_group()
        if @output_attr_obj.is_node_attribute?()
          node_group = @output_attr_obj.node_group()
          node_group_attrs = node_group.get_node_attributes()
          pp [:node_group_attrs,node_group_attrs]
        end
        nil
      end
    end
  end
end; end

