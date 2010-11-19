require 'active_support/ordered_hash'
require 'json'
module XYZ
  class SerializeToJSON
    def self.serialize(obj)
      return obj unless obj.kind_of?(Hash) or obj.kind_of?(Array)
      ordered_obj = ret_ordered_object(obj)
      ordered_obj.to_json
    end
   private
    def self.ret_ordered_object(obj)
      return obj unless obj.kind_of?(Hash) or obj.kind_of?(Array)
      if obj.kind_of?(Array)
        obj.map{|x|ret_ordered_object(x)}
      else
        ordered_hash = ActiveSupport::OrderedHash.new()
        sorted_keys(obj.keys).each{|key|ordered_hash[key] = ret_ordered_object(obj[key])}
        ordered_hash
      end
    end
    def self.sorted_keys(keys)
      keys.sort{|a,b|a.to_s <=> b.to_s}
    end
  end
end
