module DTK
  class HashObject
    class AutoViv < self
      def [](x)
        result = frozen? ? (super if key?(x)) : super
        convert_type(result)
      end

      def recursive_freeze
        each_value { |el| el.recursive_freeze if el.respond_to?(:recursive_freeze) }
        freeze
      end

      def ArrayClass
        ArrayObject
      end

      def convert_type(string_literal)
        case string_literal
        when /^true$/i
          true
        when /^false$/i
          false
        else
          string_literal
        end
      end

      class << self
        # auto vivification trick from http://t-a-w.blogspot.com/2006/07/autovivification-in-ruby.html
        def create
          self.new { |h, k| h[k] = self.new(&h.default_proc) }
        end
      end
    end
  end
end
