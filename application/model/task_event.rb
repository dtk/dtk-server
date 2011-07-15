module XYZ
  class TaskEvent < Model
    def self.create_event?(event_type,task)
      action = task[:executable_action]
      return nil unless action
      if action.kind_of?(TaskAction::CreateNode) and event_type == :start
        StartCreateNode.create?(action)
      elsif action.kind_of?(TaskAction::ConfigNode) and event_type == :start
        StartConfigNode.create?(action)
      end
    end

    class Event < HashObject
      def self.create?(action)
        is_no_op?(action) ? nil : new(action)
      end
     private
      #gets overritten if needed
      def self.is_no_op?(action)
        nil
      end

      def attr_val_pairs(attributes)
        (attributes||[]).inject({}) do |h,a|
          name = a[:display_name].to_sym
          AttrIgnoreList.include?(name) ? h : h.merge(name => a[:attribute_value])
        end
      end
      AttrIgnoreList = [:sap__l4]
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
          :action => "create_node",
          :node_name => node[:display_name],
          :node_type => ext_ref_type.to_s,
        }
        #TODO: should encapsulate this in call to iaas sdapter
        case ext_ref_type
        when "ec2_instance", "ec2_image" #TODO: may chaneg code so dont get ec2_image
          hash.merge!(:image_id => ext_ref[:image_id])
        else 
          Log.error("external ref type #{ext_ref_type} not treated")
        end
        hash.merge(attr_val_pairs(action[:attributes]))
        super(hash)
      end
    end

    class StartConfigNode < Event
      def initialize(action)
        cmp_info = action[:component_actions].map do |cmp_attrs|
          {:component_name => cmp_attrs[:component][:display_name]}.merge(attr_val_pairs(cmp_attrs[:attributes]))
        end
        super(:action => "config_node", :components => cmp_info)
      end
    end
  end
end
