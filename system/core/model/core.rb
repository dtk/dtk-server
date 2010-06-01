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
  end
  class RefObjectPairs < HashObject
  end
end

