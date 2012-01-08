r8_require_util_library("hash_object")

module R8
  module Client
    class ViewProcHashPrettyPrint < ViewProcessor
      include XYZ
      def render(hash)
        object_def = get_top_def()
        raise_error() unless object_def
        render_object_def(hash,object_def)
      end
     private
      def  get_top_def()
        raise_error("No Top def") unless top_object_type = meta[:top_type]
        get_object_def(top_object_type)
      end

      def get_object_def(object_type)
        if defs = meta[:defs]
          defs["#{object_type}_def".to_sym]
        end
      end
      def raise_error(msg=nil)
        msg ||= "No hash pretty print view defined"
        raise Error.new(msg)
      end
      def render_object_def(hash,object_def)
        #TODO: stub making it only first level
        ret = PrettyPrintHash.new

        object_def.each do |item|
          if item.kind_of?(Hash)
          else
            key = item.to_s
            ret[key] = hash[key] if hash[key]
          end
        end
        #catch all for keys not defined
        (hash.keys - ret.keys).each do |key|
          ret[key] = hash[key]
        end
        ret
      end
    end
  end
end
