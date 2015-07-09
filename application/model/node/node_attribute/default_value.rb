module DTK; class Node
  class NodeAttribute
    module DefaultValue
      def self.host_addresses_ipv4
        {
          required: false,
          read_only: true,
          is_port: true,
          cannot_change: false,
          data_type: 'json',
          value_derived: [nil],
          semantic_type_summary: 'host_address_ipv4',
          display_name: 'host_addresses_ipv4',
          dynamic: true,
          hidden: true,
          semantic_type: {':array'=>'host_address_ipv4'}
        }
      end

      def self.fqdn
        {
          required: false,
          read_only: true,
          is_port: true,
          cannot_change: false,
          data_type: 'string',
          display_name: 'fqdn',
          dynamic: true,
          hidden: true
        }
      end

      def self.node_components
        {
          required: false,
          read_only: true,
          is_port: true,
          cannot_change: false,
          data_type: 'json',
          display_name: 'node_components',
          dynamic: true,
          hidden: true
        }
      end
    end
  end
end; end
