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

        assembly_part = aug_node[:assembly]
        node_part = aug_node[:display_name]
        user_part = CurrentSession.get_username()
        unless tenant_part = ::R8::Config[:dns][:r8][:tenant_name]
          raise Error.new("Server config variable (dns.r8.tenant_name) has not been set")
        end
        unless domain = ::R8::Config[:dns][:r8][:domain]
          raise Error.new("Server config variable (dns.r8.domain) has not been set")
        end
        dns_address = "#{node_part}.#{assembly_part}.#{user_part}.#{tenant_part}.#{domain}"
        Assignment.new(dns_address)
      end
    end
  end
end

