module DTK
  class ModuleDSL
    class ParsingError
      class IllegalKeys < self
        def initialize(key_or_keys)
          keys = (key_or_keys.is_a?(Array) ? key_or_keys : [key_or_keys])
          super(keys.size == 1 ?  "illegal key (#{keys.first})" : "illegal keys (#{keys.join(',')})")
        end
      end
    end
  end
end
