module XYZ
  module CommandAndControlAdapter
    class Mcollective__mock < CommandAndControlNodeConfig
      def self.execute(task_idh,top_task_idh,config_node,attributes_to_set)
        node_name = ((config_node[:node]||{})[:external_ref]||{})[:instance_id] || "i-c18838ad" #TODO: stubbed instance name
        result = {
          :status=>:succeeded, 
          :node_name=>node_name
        }
        updated_attributes = Array.new
        sleep MockTimes[:execution]
        [result,updated_attributes]
      end
      MockTimes = {
        :execution => 5,
        :node_ready => 3
      }

      def self.wait_for_node_to_be_ready(node)
        sleep MockTimes[:node_ready]
      end
      def self.poll_to_detect_node_ready(node,opts)
        wait_for_node_to_be_ready(node)
        rc = opts[:receiver_context]
        msg = Hash.new #TODO: stub
        rc[:callbacks][:on_msg_received].call(msg)
      end
    end
  end
end

