#TODO: initially enterred through the simple dsl; may then put in model that uses db persistence, but caches this
module DTK
  class Attribute 
    class SemanticDatatype
#TODO: remove; for testing    
#      require '/home/dtk18/server/application/model/attribute/semantic_datatype/dsl_builder'
      r8_nested_require('semantic_datatype','asserted_datatypes')
      extend SemanticDatatypeClassMixin
      include SemanticDatatypeMixin
      def initialize(name)
        @name = name.to_s
        @datatype = nil
        @parent = nil
        @validation = nil
      end
      #this must be placed here
#TODO: remove; for testing    
#      require '/home/dtk18/server/application/model/attribute/semantic_datatype/asserted_datatypes'
      r8_nested_require('semantic_datatype','dsl_builder')

      def self.validate_and_find_base_datatype(semantic_datatype)
      end
    end
  end
end

