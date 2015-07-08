require File.expand_path("mixins/security_group", File.dirname(__FILE__))

module XYZ
  module DSConnector
    class Ec2 < Top
      def initialize_extra
        @flavor_cache = Aux::Cache.new
        @network_partition_cache = Aux::Cache.new
        @server_cache =  Aux::Cache.new
      end

      include Ec2SecurityGroupInstanceMixin
      def get_objects__node__instance(&block)
        servers = get_servers()
        servers.each do |server|
          block.call(DataSourceUpdateHash.new(server).freeze)
        end
        # TODO: qualify that comes from ec2 or chef-ec2
        return HashIsComplete.new({type: "instance"}) #TODO; this prunes chef dicovred instances that no longer exist
      end

      def get_objects__node__image(&block)
        # TODO: stubbed so that just brings in images currently used
        servers = get_servers()
        images = {}
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
        # TODO: qualify that comes from ec2
        return HashIsComplete.new({type: "image"})
      end

      def get_objects__network_partition(&block)
        get_network_partitions.each_value do |network_partition_ds|
          block.call(network_partition_ds)
        end
        return HashIsComplete.new()
      end

      def get_objects__node_group(&block)
        get_network_partitions.each_key do |ref|
          security_groups = security_groups_from_network_partition_ref(ref)
          values = {
            ref: node_group_ref(ref),
            display_name: "ec2 security groups [#{security_groups.join(",")}]",
            security_groups: security_groups
          }
          block.call(DataSourceUpdateHash.new(values))
        end
        return HashMayNotBeComplete.new()
      end

      def get_objects__node_group_member(&block)
        # TODO: using now explict links to node group; should dynamic sql be used instead?
        get_servers().each do |server|
          next unless server[:network_partition_ref]
          node_ref = server[:id]
          node_group_ref = node_group_ref(server[:network_partition_ref])
          values = {
            ref: "#{node_group_ref}--#{node_ref}",
            node_ref: node_ref,
            node_group_ref: node_group_ref
          }
          block.call(DataSourceUpdateHash.new(values))
        end
        return HashMayNotBeComplete.new()
      end

      def get_servers
        @server_cache[:servers] ||= get_servers_aux()
      end

      private

      def get_servers_aux
        ret = conn().servers_all()
        ret.each do |server|
          server[:flavor] = get_flavor(server)
          server[:network_partition_ref] = get_network_partition_ref(server)
        end
        ret
      end

      def node_group_ref(network_partition_ref)
        "ec2_sg_#{network_partition_ref}"
      end

      def conn
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
