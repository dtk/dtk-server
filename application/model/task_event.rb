module XYZ
  class TaskEvent < Model
    def self.create_event?(event_type, task, result)
      action = task[:executable_action]
      return nil unless action
      if action.is_a?(Task::Action::PowerOnNode)
        # TODO: Look into this see if neccessery
        Log.warn 'TODO: >>>>>>>> CREATING POWER ON NODE EVEN <<<<<<<<< IMPLEMENTATION NEEDED'
        nil
      elsif action.is_a?(Task::Action::CreateNode)
        case event_type
         when :start
          StartCreateNode.create_start?(action)
         when :complete_succeeded, :complete_failed, :complete_timeout
          CompleteCreateNode.create_complete?(action, event_type, result)
        end
      elsif action.is_a?(Task::Action::ConfigNode)
        case event_type
         when :start
          StartConfigNode.create_start?(action)
         when :complete_succeeded, :complete_failed, :complete_timeout
          CompleteConfigNode.create_complete?(action, event_type, result)
        end
      end
    end

    class Event < HashObject
      def self.create_start?(action)
        is_no_op?(action) ? nil : new(action)
      end
      def self.create_complete?(action, status, result)
        is_no_op?(action) ? nil : new(action, status, result)
      end

      private

      # gets overritten if needed
      def self.is_no_op?(_action)
        nil
      end

      def attr_val_pairs(attributes)
        (attributes || []).inject({}) do |h, a|
          name = a[:display_name].to_sym
          AttrIgnoreList.include?(name) ? h : h.merge(name => a[:attribute_value])
        end
      end
      AttrIgnoreList = [:sap__l4]
    end

    class StartCreateNode < Event
      # TODO: should encapsulate this at workflow or iaas level
      def self.is_no_op?(action)
        ext_ref = action[:node][:external_ref]
        ext_ref[:type] == 'ec2_instance' && ext_ref[:instance_id]
      end

      def initialize(action)
        node = action[:node]
        ext_ref = node[:external_ref]
        ext_ref_type = ext_ref[:type]
        hash = {
          event: 'initiating_create_node',
          node_name: node[:display_name],
          node_type: ext_ref_type.to_s
        }
        # TODO: should encapsulate this in call to iaas sdapter
        case ext_ref_type
        when 'ec2_instance', 'ec2_image' #TODO: may chaneg code so dont get ec2_image
          hash.merge!(image_id: ext_ref[:image_id])
        else
          Log.error("external ref type #{ext_ref_type} not treated")
        end
        hash.merge(attr_val_pairs(action[:attributes]))
        super(hash)
      end
    end

    class CompleteCreateNode < Event
      def initialize(action, status, result)
        node = action[:node]
        ext_ref = node[:external_ref]
        ext_ref_type = ext_ref[:type]
        hash = {
          event: 'completed_create_node',
          node_name: node[:display_name],
          node_type: ext_ref_type.to_s,
          status: status
        }
        hash.merge(attr_val_pairs(action[:attributes]))
        if status == :complete_failed
          if error_msg = error_msg(result)
            hash.merge!(error_msg: error_msg)
          end
        end
        super(hash)
      end

      private

      def error_msg(result)
        # TODO: stub
        if error_obj = result[:error_object]
          error_obj.to_s
        end
      end
    end

    class StartConfigNode < Event
      def initialize(action)
        cmp_info = action.component_actions().map do |cmp_attrs|
          attr_info = attr_val_pairs(cmp_attrs[:attributes].reject { |a| a[:dynamic] })
          { component_name: cmp_attrs[:component][:display_name] }.merge(attr_info)
        end
        hash = {
          event: 'initiating_config_node',
          node_name: action[:node][:display_name],
          components: cmp_info
        }
        super(hash)
      end
    end

    class CompleteConfigNode < Event
      def initialize(action, status, result)
        hash = {
          event: status.to_s,
          node_name: action[:node][:display_name],
          components: action.component_actions().map { |cmp_attrs| cmp_attrs[:component][:display_name] }
        }
        if errors = (result[:data] || {})[:errors]
          hash.merge!(errors: errors)
        end
        dyn_attrs = dynamic_attributes(status, result)
        hash.merge!(dynamic_attributes: dyn_attrs) unless dyn_attrs.empty?
        super(hash)
      end

      private

      def dynamic_attributes(status, result)
        ret = {}
        return ret unless status == :complete_succeeeded
        return ret unless dyn_attrs = (result[:data] || {})[:dynamic_attributes]
        dyn_attrs.each do |da|
          cmp = ret[da[:component_name]] ||= {}
          cmp[da[:attribute_name]] = da[:attribute_val]
        end
        ret
      end
    end
  end
end
