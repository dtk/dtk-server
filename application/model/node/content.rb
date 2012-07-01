r8_require('../content_object_type')
module DTK
  class Node
    class Content < Node
      extend ContentObjectClassMixin
      r8_nested_require('content','instance')
    end
  end
end
