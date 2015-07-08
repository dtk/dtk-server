module XYZ
  module CommandAndControlAdapter
    class Mcollective__mock < CommandAndControlNodeConfig
      def self.execute(_task_idh,_top_task_idh,config_node,_attributes_to_set)
        node_name = ((config_node[:node]||{})[:external_ref]||{})[:instance_id] || "i-c18838ad" #TODO: stubbed instance name
        result = {
          status: :succeeded,
          node_name: node_name
        }
        updated_attributes = []
        sleep MockTimes[:execution]
        [result,updated_attributes]
      end
      MockTimes = {
        execution: 5,
        node_ready: 3
      }

      def self.wait_for_node_to_be_ready(_node)
        sleep MockTimes[:node_ready]
      end
      def self.poll_to_detect_node_ready(node,opts)
        wait_for_node_to_be_ready(node)
        rc = opts[:receiver_context]
        msg = {} #TODO: stub
        rc[:callbacks][:on_msg_received].call(msg)
      end
    end
  end
end

