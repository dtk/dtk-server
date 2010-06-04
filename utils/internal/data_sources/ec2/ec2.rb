require File.expand_path("../cloud_connect.rb", File.dirname(__FILE__))

module XYZ
  module DSAdapter
    class Ec2
      class Top < DataSourceAdapter
        class << self
          def get_objects__node__instance()
            ret = conn().servers_all()
            #resolve flavor info
            #TBD: this this is very static this may be cached somewhere; would like to write
            #pattern where info cached and refreshed only when needed
            flavor_cache = Cache.new
            ret.each do |server|
              flavor = flavor_cache.get(server[:flavor_id]){|id| conn().flavor_get(id)}
              server[:flavor] = flavor if flavor
            end
            ret
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
end       
