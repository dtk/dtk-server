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
        sleep(5)
        [result,updated_attributes]
      end

      def self.wait_for_node_to_be_ready(node)
        sleep(5)
      end
    end
  end
end

