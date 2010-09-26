module XYZ
  module DSConnector
    module Ec2SecurityGroupInstanceMixin
      def get_network_partitions()
        @network_partition_cache[:network_partions] ||= Local.new(conn()).get_network_partitions()
      end

      def get_server_network_partition(server)
        return nil unless server[:groups] and not server[:groups].empty? 
        Local.new(conn()).get_server_network_partition(server[:groups],get_network_partitions())
      end

      class NetworkPartitionDSHash < DataSourceUpdateHash
        def initialize(name)
          super({:name => name})
        end
      end
      
      #internal fns for mixin
      class Local
        def initialize(conn)
          @conn = conn
        end
        def get_network_partitions()
          singletons = get_unfettered_security_groups()
          network_partition_names = ret_all_possible_group_names(singletons.map{|sg|sg[:name]})

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
        def get_unfettered_security_groups()
          security_groups = @conn.security_groups_all()
          security_groups.reject{|sg|not is_unfettered_security_group?(sg)}
        end

        #using aggregate group names, rather than singletons to fit with the network partition model
        def ret_all_possible_group_names(singleton_names)
          ret_combinations(singleton_names.sort)
        end

        def ret_combinations(sorted_list)
          return sorted_list if sorted_list.size < 2
          rest = ret_combinations(sorted_list[1..sorted_list.size-1])
          rest.map{|x|"#{sorted_list.first.to_s}#{"__"}#{x}"} + rest
        end
        def ret_aggregate_name_from_group_list(group_name_list)
          group_name_list.sort.join("__")
        end

        #determines whether security group allows unfettered connectivity between its members
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
