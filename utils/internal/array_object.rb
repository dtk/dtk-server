module XYZ
  class ArrayObject < Array
    def map(&block)
      ret = ArrayObject.new
      each{|x|ret << block.call(x)}
      ret
    end
    def freeze()
      each{|x|x.freeze}
      super
    end

    def id_handles()
      map{|x|x.id_handle()}
    end
  end
end
