module DTK; class CloudConnect
  class EC2
    class ImageInfoCache
      def initialize(type, conn)
        @@cache ||= initialize_cache

        @region = conn.region
        @type  = type
        unless type_info = @@cache[type]
          fail Error.new("Caching of type '#{type}' not supported")
        end
        @region_info = type_info[@region] ||= {}
      end

      def self.get_or_set(type, conn, image_id, opts = {}, &block)
        new(type, conn).get_or_set(image_id, opts, &block)
      end

      MutexPerType = {}
      def get_or_set(image_id, opts = {}, &block)
        if opts[:mutex]
          lock = MutexPerType[@type] ||= Mutex.new
          lock.synchronize do 
            get_or_set_direct_call(image_id, &block)
          end
        else
          get_or_set_direct_call(image_id, &block)
        end
      end

      private

      Cache = {
        image_get: {}
      }

      def get_or_set_direct_call(image_id, &block)
        get?(image_id) || set(image_id, &block)
      end

      def initialize_cache
        Cache
      end

      def type_info(type)

      end

      def get?(image_id)
 #       @region_info[image_id]
        ret = @region_info[image_id]
        if ret
          Log.info_pp(["using image cache for",self, image_id])
          ret
        end
      end
        
      def set(image_id, &block)
#        @region_info[image_id] = yield
        Log.info_pp(["setting image cache for",self, image_id])
        ret = @region_info[image_id] = yield
        Log.info_pp(["finished call", @@cache])
        ret
      end
    end
  end
end; end

