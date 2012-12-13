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
        assembly_part = qualified_name(r8_dns_info[:assembly])
        node_part = qualified_name(r8_dns_info)
        tenant_part = ::R8::Config[:dns][:r8][:tenant_name]
        domain = ::R8::Config[:dns][:r8][:domain]
        "#{assembly_part}.#{node_part}.#{tenant_part}.#{domain}"
      end

      def self.qualified_name(obj)
        obj[:ref] + (obj[:ref_num] ? "-#{obj[:ref_num]}" : "") 
      end
    end
  end
end
