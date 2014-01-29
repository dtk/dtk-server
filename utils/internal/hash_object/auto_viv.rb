module DTK
  class HashObject
    class AutoViv < self
      def [](x)
        frozen? ? (super if has_key?(x)) : super
      end
      
      def recursive_freeze()
        each_value{|el| el.recursive_freeze if el.respond_to?(:recursive_freeze)}
        freeze
      end
      
      def ArrayClass()
        ArrayObject
      end

      class << self
        #auto vivification trick from http://t-a-w.blogspot.com/2006/07/autovivification-in-ruby.html
        def create()
          self.new{|h,k| h[k] = self.new(&h.default_proc)}
        end
      end
    end
  end
end
