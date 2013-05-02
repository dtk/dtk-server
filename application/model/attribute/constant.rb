module DTK
  class Attribute
    module ConstantMixin
      def is_constant?()
        external_ref = get_field?(:external_ref)
        Constant.is_constant?(external_ref)
      end
    end

    class Constant
      attr_reader :datatype

      ExternalRefType = "constant"
      def self.ret_external_ref()
        {"type" => ExternalRefType}
      end
      def self.is_constant?(external_ref)
        #this is specifically a symbol because external_ref's keys are symbols
        external_ref[:type] == ExternalRefType
      end

      def initialize(constant,dep_attr_ref,dep_cmp,datatype)
        @dependent_attribute = dep_attr_ref
        @dependent_component = dep_cmp
        @constant = constant
        @datatype = datatype.to_s
      end

      ConstantDelim = "___"
      def attribute_name()
        "#{ConstantDelim}constant#{ConstantDelim}#{@dependent_component}#{ConstantDelim}#{@dependent_attribute}#{ConstantDelim}#{constant_val_for_attr_name()}"
      end
      def attribute_value()
        @constant
      end

      def constant_val_for_attr_name()
        @constant.gsub(/[ {}\[\]:*'"]/,"X") #TODO: this is just heuristic; possible naem clash but very unlikely
      end
      
    end
  end
end
