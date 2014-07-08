module DTK
  class TestDSL
    class ParsingError 
      class MissingKey < self
        def initialize(key)
          super("missing key (#{key})")
        end
      end
    end
  end
end
