module XYZ
  class TaskEvent < Model
    def self.create_event?(event_type,task)
      action = task[:executable_action]
      return nil unless action
      if action.kind_of?(TaskAction::CreateNode) and event_type == :start
        StartCreateNode.create?(action)
      end
    end

    class Event < HashObject
      def to_hash()
        self
      end

      def self.create?(action)
        is_no_op?(action) ? nil : new(action)
      end
     private
      def attributes(action)
        (action[:attributes]||[]).inject({}){|h,a|h.merge(a[:display_name].to_sym => a[:attribute_value])}
      end

      #gets overritten if needed
      def self.is_no_op?(action)
        nil
      end
    end
  
    class StartCreateNode < Event
      #TODO: should encapsulate this at workflow or iaas level
      def self.is_no_op?(action)
        ext_ref = action[:node][:external_ref]
        ext_ref[:type] == "ec2_instance" and ext_ref[:instance_id]
      end
      
      def initialize(action)
        node = action[:node]
        ext_ref = node[:external_ref]
        ext_ref_type = ext_ref[:type]
        hash = {
          :node_name => node[:display_name],
          :node_type => ext_ref_type,
        }
        #TODO: should encapsulate this in call to iaas sdapter
        case ext_ref_type
        when "ec2_instance", "ec2_image" #TODO: may chaneg code so dont get ec2_image
          hash.merge!(:image_id => ext_ref[:image_id])
        else 
          Log.error("external ref type #{ext_ref_type} not treated")
        end
        hash.merge(attributes(action))
        super(hash)
      end
    end
  end
end
