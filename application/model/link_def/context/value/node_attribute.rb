module DTK; class LinkDefContext
  class Value 
    class NodeAttribute < self
      include AttributeMixin
      attr_reader :attribute_ref,:node_ref
      def initialize(term,opts={})
        super(nil)
        @node_ref = term[:node_name]
        @attribute_ref = term[:attribute_name]
        @node_mappings =  opts[:node_mappings]
      end
      
      def is_node_attribute?()
        true
      end
      
      def pp_form()
        attr =  @attribute.get_field?(:display_name)
        node = node().get_field?(:display_name)
        "#{node}/#{attr}"
      end
      
      # this should only be called on anode group; it returns the assocaited attributes
      # on the nod egoup members
      def get_node_group_member_attributes()
        node_group_attrs = node_group().get_node_attributes()
        attr_name = @attribute.get_field?(:display_name)
        node_group_attrs.select{|a|a[:display_name] == attr_name}
      end
      
     private
      def ret_node()
        @node_mappings[@node_ref.to_sym]
      end
    end
  end
end; end
