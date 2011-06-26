module XYZ
  #TODO: if commanality between this and Chef then move to parent class
  #TODO!!!!: probably need to rewrite, like for chef to include all attributes; not just ones that changes
  module ConfigAgentAdapter
    class Puppet < ConfigAgent
      def ret_msg_content(config_node)
        {:components_with_attributes => components_with_attributes(config_node)}
      end
      def type()
        :puppet
      end
     private
      def components_with_attributes(config_node)
        config_node[:component_actions].map do |component_action|
          {component(component_action) => ret_attributes(component_action)}
        end
      end

      def component(action)
        ((action[:component]||{})[:external_ref]||{})[:manifest_name]
      end
      def ret_attributes(action,opts={})
        ret = Hash.new
        (action[:attributes]||[]).each do |attr|
          var_name_path = (attr[:external_ref]||{})[:path]
          val = attr[:attribute_value]
          add_attribute!(ret,to_array_form(var_name_path,opts),val) if var_name_path
        end
        ret
      end

      def add_attribute!(ret,array_form_path,val)
        size = array_form_path.size
        if size == 1
          #TODO: after testing remove setting nils
          ret[array_form_path.first] = val
        else
          ret[array_form_path.first] ||= Hash.new
          add_attribute!(ret[array_form_path.first],array_form_path[1..size-1],val)
        end
      end

      #TODO: centralize this fn so can be used here and when populate external refs
      #TODO: assume form is node[component][x1] or node[component][x1][x2] or ..
      #service[component][x1] or service[component][x1][x2] or ..
      def to_array_form(external_ref_path,opts)
        #TODO: use regexp disjunction
        external_ref_path.gsub(/^node\[/,"").gsub(/^service\[/,"").gsub(/\]$/,"").split("][")
      end
    end
  end
end

