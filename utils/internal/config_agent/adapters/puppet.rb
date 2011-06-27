module XYZ
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
          if cmp = component(component_action)
            cmp.merge("attributes" => ret_attributes(component_action))
          end
        end.compact
      end

      def component(action)
        if ext_ref = (action[:component]||{})[:external_ref]
          case ext_ref[:type]
            when "puppet_class"
            {"component_type" => "class", "name" => ext_ref[:class_name]}
            when "puppet_definition"
            {"component_type" => "definition", "name" => ext_ref[:definition_name]}
          end
        end
      end
      def ret_attributes(action,opts={})
        qualified_ret = Hash.new
        (action[:attributes]||[]).each do |attr|
          var_name_path = (attr[:external_ref]||{})[:path]
          if val = attr[:attribute_value]
            add_attribute!(qualified_ret,to_array_form(var_name_path,opts),val) if var_name_path
          end
        end
        #TODO: this is based on chef convention of prefacing all attributes with implementation name
        #consider of using refs such as node[:foo] rather than node[:impl][:foo]
        qualified_ret.values.first || {}
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

