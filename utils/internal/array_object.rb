module XYZ
  class ArrayObject < Array
    def map(&block)
      ret = ArrayObject.new
      self.each{|x|ret << block.call(x)}
      ret
    end
    def freeze()
      self.each{|x|x.freeze}
      super
    end
  end
end
