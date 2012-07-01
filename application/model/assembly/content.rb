r8_require('../content_object_type')
module DTK
  class Assembly
    class Content < Assembly
      extend ContentObjectClassMixin
      r8_nested_require('content','instance')
    end
  end
end
