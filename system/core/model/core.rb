require SYSTEM_DIR + 'db'
require File.expand_path('model/schema', File.dirname(__FILE__))
require File.expand_path('model/data', File.dirname(__FILE__))

module XYZ
  class Model < HashObject 
    extend ModelSchema
    extend ModelDataClassMixins
    include ModelDataInstanceMixins
  end
end

