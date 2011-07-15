module XYZ
  class TaskEvent < Model
    def self.create?(event_type,task)
      action = task[:executable_action]
      return nil unless action
      if action.kind_of?(TaskAction::CreateNode) and event_type == :start
        TaskEventStartCreateNode.create?(action)
      end
    end

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
    def is_no_op?(action)
      nil
    end

  end

  class TaskEventStartCreateNode < TaskEvent
    #TODO: should encapsulate this at workflow or iaas level
    def self.is_no_op?(action)
      ext_ref = action[:node][:external_ref]
      ext_ref[:type] == "ec2_instance" and ext_ref[:insatnce_id]
    end

    def initialize(action)
      node = action[:node]
      ext_ref = node[:external_ref]
      ext_ref_type = ext_ref[:type]
      ret = {
        :node_name => node[:display_name],
        :node_type => ext_ref_type,
      }
      #TODO: should encapsulate this in call to iaas sdapter
      case ext_ref_type
       when "ec2_instance"
        ret.merge!(:image_id => ext_ref[:image_id])
       else 
        Log.error("external ref type #{ext_ref_type} not treated")
      end
      ret.merge(attributes(action))
    end
  end
end
