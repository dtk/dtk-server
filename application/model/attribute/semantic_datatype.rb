#TODO: initially enterred through the simple dsl; may then put in model that uses db persistence, but caches this
module DTK
  class Attribute 
    class SemanticDatatype
      r8_nested_require('semantic_datatype','dsl_builder')
      extend SemanticDatatypeClassMixin
      include SemanticDatatypeMixin

      attr_reader :datatype
      def initialize(name)
        @name = name.to_s
        @datatype = nil
        @parent = nil
        @validation_proc = nil
      end
      #this must be placed here
      r8_nested_require('semantic_datatype','asserted_datatypes')

      def self.default()
        DefaultDatatype
      end
      DefaultDatatype = :string

      def self.convert_and_raise_error_if_not_valid(semantic_datatype,value,opts={})
        if value.nil?
          return nil
        end
        unless is_valid?(semantic_datatype,value)
          if opts[:attribute_name]
            raise ErrorUsage.new("Attribute (#{opts[:attribute_name]}) has default (#{value.inspect}) that does not match its type (#{semantic_data_type})")
          else
            raise ErrorUsage.new("Value (#{value.inspect}) that does not match its type (#{semantic_data_type})")
          end
        end
        convert_to_internal_form(semantic_datatype,value)
      end

      def self.is_valid?(semantic_datatype,value)
        value.nil? or lookup(semantic_datatype).is_valid?(value)
      end

      def self.datatype(semantic_datatype)
        lookup(semantic_datatype).datatype()
      end
      
      def is_valid?(value)
        @validation_proc.nil? or @validation_proc.call(value)
      end

      def self.isa?(term)
        all_types().has_key?(term.to_sym)
      end
     private
      def self.lookup(semantic_datatype)
        unless ret = all_types()[semantic_datatype.to_sym]
          raise ErrorUsage.new("Illegal datatype (#{semantic_datatype})")
        end
        ret
      end

      def self.convert_to_internal_form(semantic_datatype,value)
        lookup(semantic_datatype).convert_to_internal_form(value)
      end
      def convert_to_internal_form(value)
        @internal_form_proc ? @internal_form_proc.call(value) : value
      end

    end
  end
end

