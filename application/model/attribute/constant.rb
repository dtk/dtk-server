module DTK
  class Attribute
    module ConstantMixin
      def is_constant?()
        external_ref = get_field?(:external_ref)
        Constant.is_constant?(external_ref)
      end
    end

    class Constant
      attr_reader :datatype,:dependent_attribute,:dependent_component

      def same_constant?(c2)
        dependent_attribute == c2.dependent_attribute and dependent_component ==  c2.dependent_component
      end
      def is_in?(constant_array)
        !!constant_array.find{|c2|same_constant?(c2)}
      end

      def self.side_effect_settings()
        {'hidden' => true}
      end

      ExternalRefType = "constant"
      def self.ret_external_ref()
        {"type" => ExternalRefType}
      end
      def self.is_constant?(external_ref)
        # this is specifically a symbol because external_ref's keys are symbols
        if type = (external_ref||{})[:type]
          type == ExternalRefType
        end
      end

      def self.create?(constant,dep_attr_ref,dep_cmp,datatype)
        if is_valid_const?(constant)
          new(constant,dep_attr_ref,dep_cmp,datatype)
        end
      end

      def initialize(constant,dep_attr_ref,dep_cmp,datatype)
        @dependent_attribute = dep_attr_ref
        @dependent_component = dep_cmp
        @constant = constant
        @datatype = datatype.to_s
      end

      ConstantDelim = "___"
      def attribute_name()
        constant_val_for_attr_name = self.class.constant_val_for_attr_name(@constant)
        "#{ConstantDelim}constant#{ConstantDelim}#{@dependent_component}#{ConstantDelim}#{@dependent_attribute}#{ConstantDelim}#{constant_val_for_attr_name}"
      end
      def attribute_value()
        @constant
      end

     private
      def self.constant_val_for_attr_name(constant)
        constant.gsub(OtherChars,OtherCharsReplacement)
      end
      def self.is_valid_const?(constant)
        !!(constant_val_for_attr_name(constant) =~ AttributeTermRE)
      end
      SimpleTokenPat = 'a-zA-Z0-9_-' #TODO: should encapuslate with def in model/link_def/parse_serialized_form.rb of  SimpleTokenPat
      AttributeTermRE = Regexp.new("^[#{SimpleTokenPat}]+$")
      OtherChars = Regexp.new("[^#{SimpleTokenPat}]")
      OtherCharsReplacement = 'X' #TODO: this is just heuristic; possible naem clash but very unlikely
    end
  end
end
