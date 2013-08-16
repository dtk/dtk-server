module DTK
  class DNS
    class R8 < self
      def self.generate_node_assignment?(node)
        ret = nil
        sp_hash = {
          :cols => [:r8_dns_info,:id,:group_id,:display_name,:ref,:ref_num]
        }
        r8_dns_info = node.get_obj(sp_hash,:keep_ref_cols => true)
        r8_dns_info && Assignment.new(generate_dns_address(r8_dns_info))
      end
     private
      def self.generate_dns_address(r8_dns_info)
        #TODO: relying on the keys below being unique; more robust would be to check againts existing names
        #TODO: to supports this may want to put in logic that prevents assemblies with explicit names from having same name
        assembly_part = assembly_part(r8_dns_info[:assembly])
        node_part = qualified_name(r8_dns_info)
        unless tenant_part = Config[:dns][:r8][:tenant_name]
          raise Error.new("Server config variable (dns.r8.tenant_name) has not been set")
        end
        unless domain = Config[:dns][:r8][:domain]
          raise Error.new("Server config variable (dns.r8.domain) has not been set")
        end
        "#{assembly_part}.#{node_part}.#{tenant_part}.#{domain}"
      end

      def self.qualified_name(obj)
        obj[:ref] + (obj[:ref_num] ? "-#{obj[:ref_num]}" : "") 
      end

      def self.assembly_part(assembly)
        if has_explicit_name?(assembly)
          assembly[:display_name]
        else
          qualified_name(assembly)
        end
      end
      
      def self.has_explicit_name?(assembly)
        assembly[:ref] != assembly[:display_name]
      end
    end
  end
end
