module DTK
  class DNS
    class R8 < self
      def self.generate_node_assignment?(node)
        ret = nil
        sp_hash = {
          :cols => [:r8_dns_info,:id,:group_id,:display_name,:ref,:ref_num]
        }
        r8_dns_info = node.get_obj(sp_hash,:keep_ref_cols => true)
        r8_dns_info && Assignment.new(generate_dns_address(r8_dns_info)
      end
     private
      def self.generate_dns_address(r8_dns_info)
        assembly_part = qualified_name(r8_dns_info[:assembly])
        node_part = qualified_name(r8_dns_info)
        tenant = R8::Config[:dns][:tenant_id]
        domain_name = R8::Config[:dns][:domain_naem]
        "#{assembly_part}.#{node_part}.#{tenant_part}.#{domain_name}"
      end

      def qualified_name(obj)
        obj[:ref] + (obj[:ref_num] ? "-#{obj[:ref_num]}" : "") 
      end
    end
  end
end
