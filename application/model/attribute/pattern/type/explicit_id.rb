module DTK; class Attribute
  class Pattern; class Type
    class ExplicitId < self
      def initialize(pattern,parent_obj)
        super(pattern)
        @id = pattern.to_i
        if parent_obj.kind_of?(::DTK::Node)
          raise_error_if_not_node_attr_id(@id,parent_obj)
        elsif parent_obj.kind_of?(::DTK::Assembly)
          raise_error_if_not_assembly_attr_id(@id,parent_obj)
        else
          raise Error.new("Unexpected parent object type (#{parent_obj.class.to_s})")
        end
      end

      def type()
        :explicit_id
      end
      
      attr_reader :attribute_idhs
      
      def set_parent_and_attributes!(parent_idh,opts={})
        @attribute_idhs = [parent_idh.createIDH(:model_name => :attribute, :id => id())]
        self
      end

      def valid_value?(value,attribute_idh=nil)
        #TODO: not testing yet valid_value? for explicit_id type
        #vacuously true
        true
      end
      
      private
      def raise_error_if_not_node_attr_id(attr_id,node)
        unless node.get_node_and_component_attributes().find{|r|r[:id] == attr_id}
          raise ErrorUsage.new("Illegal attribute id (#{attr_id.to_s}) for node")
        end
      end
      def raise_error_if_not_assembly_attr_id(attr_id,assembly)
        unless assembly.get_attributes_all_levels().find{|r|r[:id] == attr_id}
          raise ErrorUsage.new("Illegal attribute id (#{attr_id.to_s}) for assembly")
        end
      end
    end
  end; end
end; end
