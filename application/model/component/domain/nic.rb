module DTK; class Component
  class Domain
    class NIC < self
      attr_reader :security_groups
      def initialize(component)
        super
        @security_groups = match_attribute_value?(:security_groups)
      end

      def self.get_primary_nic?(node)
        ret = on_node?(node).select { |nic| nic.is_primary? }
        case ret.size
          when 0 then nil
          when 1 then ret.first
          else fail ErrorUsage, "Multiple primary nic components configured on node '#{node.get_field?(:display_name)}'"
        end
      end

      def subnet_id?
        nil
      end
      def is_primary?
        true
      end

      def self.create(component)
        if VPC.is_a?(component)
          VPC.new(component)
        else
          new(component)
        end
      end
      
      def self.component_types
        VPC.component_types
      end
      
      class VPC < self
        attr_reader :subnet_id
        def initialize(component)
          super
          @subnet_id = match_attribute_value?(:subnet_id)
        end

        def subnet_id?
          @subnet_id
        end

        def is_primary?
          ComponentTypes::Primary.include?(@component_type)
        end

        def self.component_types
          ComponentTypes::All
        end

        module ComponentTypes
          Primary   = %w{nic__primary_ec2_vpc}
          Secondary = %w{nic__secondary_ec2_vpc}
          All       = Primary + Secondary
        end
      end

    end
  end
end; end

