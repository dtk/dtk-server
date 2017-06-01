module DTKModule
  module Ec2
    class Node
      class OutputSettings < DTK::Settings
        require_relative('output_settings/create_instance')

        ADDRESS_ATTRIBUTES = [:private_ip_address, :public_ip_address, :private_dns_name, :public_dns_name, :host_addresses_ipv4]
        DYNAMIC = ADDRESS_ATTRIBUTES + [:block_device_mappings, :instance_id, :instance_state, :client_token]

        ADMIN_STATE_ATTRIBUTE = :admin_state
        LEGAL_ADMIN_STATE_VALUES = [:powered_off, :powered_on]
        
        # opts can have keys
        #   :with_nil_address_attributes
        #   :admin_state
        def initialize(opts = {})
          @with_nil_address_attributes = opts[:with_nil_address_attributes]
          @admin_state_value = legal_admin_state_value?(opts[:admin_state])
        end
        private :initialize

        # instance_info can be nil
        def self.dynamic_attributes(instance_info, opts = {})
          new(opts).set_attributes!(instance_info)
        end
        def set_attributes!(instance_info)
          set_keys!(dynamic) { |key| MapFromAwsAttributes.value(key, instance_info) } unless instance_info.nil?
          set_keys!(ADDRESS_ATTRIBUTES) { |_key| nil } if with_nil_address_attributes
          self[ADMIN_STATE_ATTRIBUTE] = admin_state_value if admin_state_value 
          self
        end

        def self.admin_state_value(symbol)
          fail "Illegal admin_state value '#{symbol}'" unless LEGAL_ADMIN_STATE_VALUES.include?(symbol)
          symbol.to_s
        end

        # modifies attributes if needed
        def self.set_create_instance_attributes!(attributes)
          CreateInstance.set_attributes!(attributes)
        end

        private
        
        attr_reader :with_nil_address_attributes, :admin_state_value

        def legal_admin_state_value?(admin_state_value = nil)
          if admin_state_value.nil?
            nil
          else
            self.class.admin_state_value(admin_state_value)
          end
        end
        def set_keys!(keys, &value_from_key)
          keys.each { |key| self[key] = value_from_key.call(key) }
        end

      end
    end
  end
end
