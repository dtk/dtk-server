require 'active_support/ordered_hash'
require 'json'
module XYZ
  class SerializeToJSON
    def self.serialize(obj)
      return obj unless obj.is_a?(Hash) || obj.is_a?(Array)
      ordered_obj = ret_ordered_object(obj)
      ordered_obj.to_json
    end

    private

    def self.ret_ordered_object(obj)
      # Hashes for Ruby 1.9.x are sorted already; so no-op for tehse
      return obj if RUBY_VERSION =~ /^1\.9\./

      return obj unless obj.is_a?(Hash) || obj.is_a?(Array)
      if obj.is_a?(Array)
        obj.map { |x| ret_ordered_object(x) }
      else
        ordered_hash = ActiveSupport::OrderedHash.new()
        sorted_keys(obj.keys).each { |key| ordered_hash[key] = ret_ordered_object(obj[key]) }
        ordered_hash
      end
    end
    def self.sorted_keys(keys)
      keys.sort { |a, b| a.to_s <=> b.to_s }
    end
  end
end
