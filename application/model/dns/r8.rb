module DTK
  class DNS
    class R8 < self
      def self.generate_node_assignment?(node)
        #TODO: relying on the keys below being unique; more robust would be to check againts existing names
        #TODO: to supports this may want to put in logic that prevents assemblies with explicit names from having same name
        sp_hash = {
          :cols => [:r8_dns_info,:id,:group_id,:display_name,:ref,:ref_num]
        }
        unless aug_node = node.get_obj(sp_hash,:keep_ref_cols => true)
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

