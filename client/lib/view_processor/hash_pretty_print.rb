r8_require_util_library("hash_object")
module R8
  module Client
    class ViewProcHashPrettyPrint < ViewProcessor
      class << self
        include XYZ
        def render(hash,meta)
          #TODO: stub making it only first level
          raise Error.new("No hash pretty print view defined for #{command}") unless meta
          ret = PrettyPrintHash.new

          meta.each do |key_x|
            key = key_x.to_s
            ret[key] = hash[key] if hash[key]
          end
          (hash.keys - ret.keys).each do |key|
            ret[key] = hash[key]
          end
          ret
        end
      end
    end
  end
end
