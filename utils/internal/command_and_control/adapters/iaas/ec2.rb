module XYZ
  module CommandAndControlAdapter
    class Ec2 < CommandAndControlIAAS
      def self.execute(task_idh,top_task_idh,task_action)
        node = task_action[:node]
        external_ref = node[:external_ref]||{}
        instance_id = external_ref[:instance_id]

        if instance_id.nil?
          ami = external_ref[:image_id]
          unless ami
            raise Error.new("cannot find ami")
          end
          raise ErrorCannotCreateNode.new unless ami
          flavor_id = external_ref[:size] || R8::Config[:command_and_control][:iaas][:ec2][:default_image_size] 
          create_options = {:image_id => ami,:flavor_id => flavor_id}

          #TODO: right now hardcoding groups
          create_options.merge!(:groups => ["basic"])
          response = conn().server_create(create_options)
          instance_id = response[:id]
          state = response[:state]
          external_ref = external_ref.merge({
            :instance_id => instance_id,
            :type => "ec2_instance"
          })
          Log.info("#{node_print_form(node)} with ec2 instance id #{instance_id}; waiting for it to be available")
          # pp [:node_created,response]
          node.merge!(:external_ref => external_ref)
          task_action.save_new_node_info(task_idh.createMH())
        else
          Log.info("node already created with instance id #{instance_id(node)}; waiting for it to be available")
        end
        {:status => "succeeded",
          :node => {
            :external_ref => external_ref
          }
        }
      end

      def self.get_updated_attributes(task_action)
        node = task_action[:node]
        instance_id = (node[:external_ref]||{})[:instance_id]
        raise Error.new("get_updated_attributes called when #{node_print_form} does not have instance id")
        attributes_to_set = task_action.attributes_to_set()
        updated_server_state = conn().server_get(instance_id)
        ret = Array.new
        attributes_to_set.each do |attr|
          unless fn = AttributeToSetMapping[attr[:display_name]]
            Log.error("no rules to process attribute to set #{attr[:display_name]}")
          else
            new_value = fn.call(updated_server_state)
            unless false #TODO: temp for testing attr[:value_asserted] == new_value
              unless new_value.nil?
                attr[:value_asserted] = new_value
                ret << attr
              end
            end
          end
        end
        ret
      end
     private

      #TODO: if can legitimately have nil value then need to change updtae
      AttributeToSetMapping = {
        "host_addresses_ipv4" =>  lambda{|server|(server||{})[:dns_name] && [server[:dns_name]]} #null if no value
      }
      
      def self.node_print_form(node)
        "#{node[:display_name]} (#{node[:id]}"
      end

      #TODO: sharing ec2 connection with ec2 datasource
      def self.conn()
        Conn[0] ||= CloudConnect::EC2.new
      end
      Conn = Array.new
    end
  end
end
