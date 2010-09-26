require File.expand_path("../cloud_connect.rb", File.dirname(__FILE__))
require File.expand_path("mixins/security_group", File.dirname(__FILE__))

module XYZ
  module DSConnector
    class Ec2 < Top
      include Ec2SecurityGroupInstanceMixin
      def get_objects__node__instance(&block)
        servers = conn().servers_all()
        #TODO: this this is very static this may be cached somewhere; would like to write
        #pattern where info cached and refreshed only when needed
        #resolve flavor info
        flavor_cache = Cache.new
        servers.each do |server|
          flavor = flavor_cache.get(server[:flavor_id]){|id| conn().flavor_get(id)}
          server[:flavor] = flavor if flavor
          block.call(DataSourceUpdateHash.new(server).freeze)
        end
        return HashIsComplete.new({:ds_source_obj_type => "instance"})
      end

      def get_objects__node__image(&block)
        #TODO: stubbed so that just brings in images currently used
        servers = conn().servers_all()
        images = Hash.new
        servers.each do |server|
          image_id = server[:image_id]
          unless images[image_id]
            image = conn().image_get(image_id)
            images[image_id] = image if image #to take care of case where image no longer exists
          end
        end
        images.values().each do |image|
          block.call(DataSourceUpdateHash.new(image).freeze)
        end
        return HashMayNotBeComplete.new()
      end

      def get_objects__network_partition__security_group(&block)
        #TODO: use cache so can provide for populating also network gateways
        get_network_partitions.each do |network_partition_ds|
          block.call(network_partition_ds)
        end
        return HashIsComplete.new()
      end
     private

      def conn()
        @@conn ||= CloudConnect::EC2.new
      end

      #TODO: may be able to remove now or put in constructor that this is instance fn
      #TODO: general fn that probably should be moved to Aux
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
