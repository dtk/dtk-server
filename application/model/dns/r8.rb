module DTK
  class DNS
    class R8 < self
      def self.generate_node_assignment?(node)
        unless aug_node = get_node_with_dns_info(node)
          #TODO: think this should be error if aug_node is nil
          return nil
        end
        unless tenant = ::R8::Config[:dns][:r8][:tenant_name]
          raise Error.new("Server config variable (dns.r8.tenant_name) has not been set")
        end
        unless domain = ::R8::Config[:dns][:r8][:domain]
          raise Error.new("Server config variable (dns.r8.domain) has not been set")
        end
        dns_info = {
          :assembly => aug_node[:assembly][:display_name],
          :node => aug_node[:display_name],
          :user => CurrentSession.get_username(),
          :tenant => tenant,
          :domain => domain
        }
        
        Assignment.new(dns_address(dns_info))
      end
     private
      def get_node_with_dns_info(node)
        #TODO: relying on the keys below being unique; more robust would be to check againts existing names
        #TODO: to supports this may want to put in logic that prevents assemblies with explicit names from having same name
        sp_hash = {
          :cols => [:r8_dns_info,:id,:group_id,:display_name,:ref,:ref_num]
        }
        #can be multiple if multiple keys allowed
        aug_nodes = node.get_objs(sp_hash,:keep_ref_cols => true)
        aug_nodes.sort do |a,b|
          dns_attr_rank(a[:attribute_r8_dns_enabled]) <=> dns_attr_rank(b[:attribute_r8_dns_enabled])
        end.first
      end
      def dns_attr_rank(attr)
        ret = HighestRank
        if attr_name = (attr||{})[:display_name]
          if rank = RankPos[attr_name]
            ret = rank
          end
        end
        ret
      end
      #TODO: move higher in class hier
      RankPos = {
        'dtk_dns_enabled' => 1,
        'r8_dns_enabled' => 2
      }
      HighestRank = RankPos.size+1

      def self.dns_address(info)
        #TODO: should validate ::R8::Config[:dns][:r8][:format]
        format = ::R8::Config[:dns][:r8][:format] || DefaultFormat
        ret = format.dup
        [:node,:assembly,:user,:tenant,:domain].each do |part|
          ret.gsub!(Regexp.new("\\${#{part}}"),info[part])
        end
        ret
      end
      DefaultFormat = "${node}.${assembly}.${user}.${tenant}.${domain}"
    end
  end
end

