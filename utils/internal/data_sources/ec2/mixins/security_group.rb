module XYZ
  module DSConnector
    module Ec2SecurityGroupInstanceMixin
      def get_network_partitions()
        @network_partition_cache[:network_partions] ||= Local.new(self).get_network_partitions()
      end

      def get_server_network_partition(server)
        return nil unless server[:groups] and not server[:groups].empty? 
        Local.new(self).get_server_network_partition(server[:groups],get_network_partitions())
      end

      class NetworkPartitionDSHash < DataSourceUpdateHash
        def initialize(name)
          super({:name => name})
        end
      end
      
      #internal fns for mixin
      class Local
        def initialize(parent)
          @parent = parent
        end
        def get_network_partitions()
          network_partition_names = get_network_partition_refs()

          ret = DataSourceUpdateHash.new
          network_partition_names.each do |name|
            network_partition = {:name => name} #TODO stub for putting more information in
            ret[name] = network_partition
          end
          ret
        end

        def get_server_network_partition(server_interface_groups,network_partitions)
          network_partitions[ret_aggregate_name_from_group_list(server_interface_groups)]
        end

       private

        def get_network_partition_refs()
          ret = Array.new
          @parent.get_servers().each do |server|
            groups = server[:groups]
            next unless groups and not groups.empty?
            name = ret_aggregate_name_from_group_list(groups)
            ret << name unless ret.include?(name)
          end
          ret
        end

        def conn()
          @parent.conn()
        end

        def ret_aggregate_name_from_group_list(group_name_list)
          group_name_list.sort.join("__")
        end

        #determines whether security group allows unfettered connectivity between its members
        #TODO: factor this in
        def get_unfettered_security_groups()
          security_groups = conn().security_groups_all()
          security_groups.reject{|sg|not is_unfettered_security_group?(sg)}
        end
        def is_unfettered_security_group?(security_group)
          rules =  security_group[:ip_permissions]
          return nil unless rules
          return true #TODO stub
          #TODO: need to replace; this is rule for right_aws, not fog rules.find{|x|x.has_key?(:group) and x[:group] == sg_name} ? true : nil
        end
      end
    end
  end
end
