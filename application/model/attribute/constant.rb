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

      def initialize(constant,dep_attr_ref,dep_cmp)
        @dependent_attribute = dep_attr_ref
        @dependent_component = dep_cmp
        @constant = constant
        @datatype = nil #TODO: stub for when constants have data types
      end

      def self.strip_constant?(attr_ref,dep_attr_ref,dep_cmp,opts={})
        ret = attr_ref
        if attr_ref =~ /^constant\:(.+$)/
          stripped_attr_ref = $1
          constant_assign = new(stripped_attr_ref,dep_attr_ref,dep_cmp)
          (opts[:constants] ||= Array.new) << constant_assign
          ret = constant_assign.attribute_name()
        end
        ret
      end

      ConstantDelim = "___"
      def attribute_name()
        "#{ConstantDelim}constant#{ConstantDelim}#{@dependent_component}#{ConstantDelim}#{@dependent_attribute}"
      end
      def attribute_value()
        @constant
      end
      
    end
  end
end
