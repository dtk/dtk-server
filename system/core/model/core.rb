#TODO: lose all of these, lose notion of schemea and data
#db inclusion shouldnt be needed or required at this level
require SYSTEM_DIR + 'db'
require File.expand_path('create_objects', File.dirname(__FILE__))
require File.expand_path('schema', File.dirname(__FILE__))
require File.expand_path('input_into_model', File.dirname(__FILE__))
require File.expand_path('data', File.dirname(__FILE__))

module XYZ
  class Model < HashObject 
    extend CreateObjectsClassMixins
    #TBD: refactoring: below is old to be refactored; above is refactored
    extend ModelSchema
    extend ModelDataClassMixins
    extend InputIntoModelClassMixins
    include ModelDataInstanceMixins

    attr_reader :relation_type, :c

    def initialize(hash_scalar_values,c,relation_type)
      return nil if hash_scalar_values.nil?

      super(hash_scalar_values)
      @c = c
      @relation_type = relation_type
      @id_handle = 
        if hash_scalar_values[:id]
          ret_id_handle_from_db_id(hash_scalar_values[:id],relation_type)
        elsif hash_scalar_values[:uri]
          IDHandle[:c =>c, :uri => hash_scalar_values[:uri]]
        else
          nil
        end
    end

    def [](x)
      return send(x) if self.class.is_virtual_column?(x)
      super(x)
    end

    #inherited virtual coulmn defs
    def parent_id()
      get_parent_id_info()[:id]
    end
    def parent_path()
      get_parent_id_info()[:uri]
    end

  end

  class RefObjectPairs < HashObject
  end
end

