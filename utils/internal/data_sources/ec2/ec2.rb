require File.expand_path("../cloud_connect.rb", File.dirname(__FILE__))
require File.expand_path("mixins/security_group", File.dirname(__FILE__))

module XYZ
  module DSConnector
    class Ec2 < Top
      def initialize()
        super
        @flavor_cache = Aux::Cache.new
        @network_partition_cache = Aux::Cache.new
        @server_cache =  Aux::Cache.new
      end

      include Ec2SecurityGroupInstanceMixin
      def get_objects__node__instance(&block)
        servers = get_servers()
        servers.each do |server|
          flavor = get_flavor(server)
          server[:flavor] = flavor if flavor
          interface_network_partition = get_server_network_partition(server)
pp [server[:id],get_server_network_partition(server)]
          block.call(DataSourceUpdateHash.new(server).freeze)
        end
        return HashIsComplete.new({:ds_source_obj_type => "instance"})
      end

      def get_objects__node__image(&block)
        #TODO: stubbed so that just brings in images currently used
        servers = get_servers()
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
        get_network_partitions.each_value do |network_partition_ds|
          block.call(network_partition_ds)
        end
        return HashIsComplete.new()
      end
      def get_servers()
        @server_cache[:servers] ||= conn().servers_all()
      end
     private

      def conn()
        @@conn ||= CloudConnect::EC2.new
      end

      def get_flavor(server)
        flavor_id = server[:flavor_id]
        return nil if flavor_id.nil?
        @flavor_cache[flavor_id] ||= conn().flavor_get(flavor_id)
      end
    end
  end
end       
