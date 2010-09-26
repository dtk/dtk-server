module XYZ
  module DSConnector
    module Ec2SecurityGroupInstanceMixin
      def get_network_partitions()
        singletons = get_unfettered_security_groups()
        ret =  ret_aggregate_groups_with_just_names(singletons)
        ret.each do |network_partition|
          #TODO stub for putting more information in
          network_partition.freeze
        end
        ret
      end

      def get_unfettered_security_groups()
        security_groups = conn().security_groups_all()
        security_groups.reject{|sg|not is_unfettered_security_group?(sg)}
      end

#TODO: hide logic here how gateway filter rules combine together

      #using aggregate group names, rather than singletons to fit with the network partition model
      def ret_aggregate_groups_with_just_names(singleton_security_groups)
        singleton_names = singleton_security_groups.map{|sg|sg[:name]}
        ret_combinations(singleton_names.sort).map{|name|NetworkPartitionDSHash.new(name)}
      end

      def ret_combinations(list)
        #assumes that names in list have been sorted
        return list if list.size < 2
        rest = ret_combinations(list[1..list.size-1])
        rest.map{|x|"#{list.first.to_s}#{"__"}#{x}"} + rest
      end

     #determines whether security group allows unfettered connectivity between its members
     def is_unfettered_security_group?(security_group)
       rules =  security_group[:ip_permissions]
       return nil unless rules
       return true #TODO stub
      #TODO: need to replace; this is rule for right_aws, not fog rules.find{|x|x.has_key?(:group) and x[:group] == sg_name} ? true : nil
     end

     class NetworkPartitionDSHash < DataSourceUpdateHash
       def initialize(name)
         super({:name => name})
       end
     end
    end
  end
end
