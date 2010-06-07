require File.expand_path("../cloud_connect.rb", File.dirname(__FILE__))

module XYZ
  module DSAdapter
    class Ec2
      class Top < DataSourceAdapter
        def get_objects__node__instance()
          ret = conn().servers_all()
          #TBD: this this is very static this may be cached somewhere; would like to write
          #pattern where info cached and refreshed only when needed
          #resolve flavor info
          flavor_cache = Cache.new
          ret.each do |server|
            flavor = flavor_cache.get(server[:flavor_id]){|id| conn().flavor_get(id)}
            server[:flavor] = flavor if flavor
          end
          ret
        end

        def get_objects__node__image()
          #TBD: stubbed so that just brings in images currently used
          servers = conn().servers_all()
          images = Hash.new
          servers.each do |server|
            image_id = server[:image_id]
            images[image_id] = conn().image_get(image_id) unless images[image_id]
          end
          images.values()
        end

       private

        def conn()
          @@conn ||= CloudConnect::EC2.new
        end

        #TBD: general fn that probably should be moved to Aux
        class Cache
          def initialize()
            @cached = Hash.new
          end
          def get(id,&block)
            return nil if id.nil?
            return @cached[id] if @cached[id]
            @cached[id] = block.call(id)
          end
        end
      end
    end
  end
end       
