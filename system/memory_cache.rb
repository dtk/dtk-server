require 'memcache'

# TBD: may have a set of these that are in different namespaces
module XYZ
  class MemoryCache
    class << self
      @@cache = nil
      def set_cache_servers(server_list)
	#TBD: hard wired port
        if server_list.empty?
	  @@cache = nil
          return nil
        end
        @@cache = MemCache.new(server_list.map{|s|s+":11211"})
      end
      def set(key,value)
        @@cache.set(key,value) unless  @@cache.nil?
      end
      def get(key)
        @@cache ? @@cache.get(key) : nil
      end
    end
  end
end