module XYZ
  class ArrayObject < Array
    def map(&block)
      ret = ArrayObject.new
      each { |x| ret << block.call(x) }
      ret
    end

    def freeze
      each(&:freeze)
      super
    end
  end
end
