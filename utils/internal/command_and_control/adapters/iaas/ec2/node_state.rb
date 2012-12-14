module DTK; module CommandAndControlAdapter
  class Ec2
    module NodeStateClassMixin
      #assumed that node[:external_ref] and  node[:hostname_external_ref] are up to date  
      def get_and_update_node_state!(node,attribute_names)
        ret = Hash.new
        unless raw_state_info = raw_state_info!(node)
          return ret 
        end

        #attribute_names in normalized form so need to convert
        change = nil
        attribute_names.each do |normalized_attr_name|
          if raw_info = AttributeToSetMapping[normalized_attr_name]
            raw_name = raw_info[:raw_name]
            raw_val = raw_state_info[raw_name]
            if normalized_val = (raw_info[:fn] ? raw_info[:fn].call(raw_state_info) : raw_val) 
              change = true
              ret[normalized_attr_name] = normalized_val
              node[:external_ref][raw_name] = raw_val
            end
          end
        end
        node.update(:external_ref => node[:external_ref]) if change
        ret
      end
      #TODO: if can legitimately have nil value then need to change update
      AttributeToSetMapping = {
        :host_addresses_ipv4 => {
          :raw_name => :dns_name,
          :fn => lambda{|raw|raw[:dns_name] && [raw[:dns_name]]} #null if no value
        },
        :fqdn => {
          :raw_name => :private_dns_name,
          :fn => lambda{|raw|raw[:dns_name] && raw[:private_dns_name] && {raw[:dns_name] => raw[:private_dns_name]}}
        }
      }

      def ec2_public_address!(node)
        if raw_state_info = raw_state_info!(node)
          raw_state_info[:dns_name]
        end
      end
     
      def get_node_operational_status(node)
        instance_id = get_instance_id_from_object(node)
        #TODO: see if more targeted get to just get operational status
        state = conn().server_get(instance_id)
        op_status = state && state[:state]
        StateTranslation[op_status] || op_status
      end
      StateTranslation = {
        "pending" => "starting",
        "shutting-down" => "stopping"
      } 

     private
      def raw_state_info!(node)
        if instance_id = get_instance_id_from_object(node)
          node[:raw_ec2_state_info] ||= conn().server_get(instance_id)
        end
      end

      def get_instance_id_from_object(node)
        node.update_object!(:external_ref)
        instance_id = (node[:external_ref]||{})[:instance_id]
        unless instance_id
          Log.error("get_node_state called when #{node_print_form(node)} does not have instance id")
          return nil
        end
        instance_id
      end
    end
  end
end; end
