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

      def ret_attribute_name_and_type(attribute)
        var_name_path = (attribute[:external_ref]||{})[:path]
        if var_name_path 
          array_form = to_array_form(var_name_path)
          {:name => array_form && array_form[1], :type => type()}
        end
      end

      def ret_attribute_external_ref(hash)
        module_name = hash[:component_type].gsub(/__.+$/,"")
        {
          :type => "#{type}_attribute",
          :path =>  "node[#{module_name}][#{hash[:field_name]}]"
        }             
      end

     private
      def components_with_attributes(config_node)
        cmp_actions = config_node[:component_actions]
        ndx_cmps = cmp_actions.inject({}) do |h,cmp_action|
          cmp = cmp_action[:component]
          h.merge(cmp[:id] => cmp)
        end
        internal_guards = config_node[:internal_guards]
        if internal_guards.empty?
          attrs_for_guards = nil
        else
          attrs_for_guards = cmp_actions.map{|cmp_action| cmp_action[:attributes]}.flatten(1)
        end
        cmp_actions.map do |cmp_action|
          component_with_deps(cmp_action,ndx_cmps).merge(ret_attributes(cmp_action,internal_guards,attrs_for_guards))
        end
      end

      def component_with_deps(action,ndx_components)
        ret = component_external_ref(action[:component])
        cmp_deps = action[:component_dependencies]
        return ret unless cmp_deps and not cmp_deps.empty?
        ret.merge("component_dependencies" => cmp_deps.map{|cmp_id|component_external_ref(ndx_components[cmp_id])})
      end
  
      def component_external_ref(component)
        ext_ref = component[:external_ref]
        case ext_ref[:type]
         when "puppet_class"
          {"component_type" => "class", "name" => ext_ref[:class_name]}
         when "puppet_definition"
          {"component_type" => "definition", "name" => ext_ref[:definition_name]}
          else
          Log.error("unexepected external type #{ext_ref[:type]}")
          nil
        end
      end

      #returns both attributes to set on node and dynmic attributes that get set by the node
      def ret_attributes(action,internal_guards,attrs_for_guards)
        #labeled as qualified attributes because first item is the module
        qual_attrs = Hash.new
        dynamic_attrs = Array.new
        (action[:attributes]||[]).each do |attr|
          if var_name_path = (attr[:external_ref]||{})[:path]
            array_form_path = to_array_form(var_name_path)
            if attr[:dynamic]
              #TODO: ignoring ones set already; this implicitly captures assumption that dynamic attribute
              #once set cnnot change
              unless attr[:attribute_value]
                #TODO: making assumption that dynamic attribute as array_form_path of form [<module>,<attrib_name>]
                dynamic_attrs << {:name => array_form_path[1], :id => attr[:id]}
              end
            elsif val = attr[:attribute_value]
              add_attribute!(qual_attrs,array_form_path,val)
              #info that is used to set the name param for the resource
              if rsc_name_path = attr[:external_ref][:name]
                if rsc_name_val = nested_value(val,rsc_name_path)
                  add_attribute!(qual_attrs,[array_form_path[0],"name"],rsc_name_val)
                end
              end
            elsif guard = internal_guards.find{|g|attr[:id] == g[:guarded][:attribute][:id]}
              val = find_reference_to_guard(guard,attrs_for_guards)
              add_attribute!(qual_attrs,array_form_path,val) if val
            end
          end
        end
        #TODO: this is based on chef convention of prefacing all attributes with implementation name
        #consider of using refs such as node[:foo] rather than node[:impl][:foo]
        ret = Hash.new
        ret.merge!("attributes" => qual_attrs.values.first) unless qual_attrs.empty?
        ret.merge!("dynamic_attributes" => dynamic_attrs) unless dynamic_attrs.empty?
        ret
      end
      
      def find_reference_to_guard(guard,attributes)
        ret = nil
        unless guard[:link][:function] == "eq"
          Log.error("not treating internal guards for link fn #{guard[:link][:function]}")
          return ret
        end

        guard_id = guard[:guard][:attribute][:id]
        attr = attributes.find{|attr|attr[:id] == guard_id}
        return nil unless attr
        return nil unless var_name_path = (attr[:external_ref]||{})[:path]
        ref_array_form_path = to_array_form(var_name_path)
        #TODO: case on whether teh ref is computed in first stage or second stage
        {"__ref" => ref_array_form_path}
      end


      #TDOO: may want to better unify how name is passed heer with 'param' and otehr way by setting node path with name last element]
      def nested_value(val,rsc_name_path)
        array_form = rsc_name_path.gsub(/^param\[/,"").gsub(/\]$/,"").split("][")
        nested_value_aux(val,array_form)
      end

      def nested_value_aux(val,array_form,i=0)
        return val unless val.kind_of?(Hash)
        return nil if i >= array_form.size
        nested_value_aux(val[array_form[i]],i+1)
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
      def to_array_form(external_ref_path)
        #TODO: use regexp disjunction
        external_ref_path.gsub(/^node\[/,"").gsub(/^service\[/,"").gsub(/\]$/,"").split("][")
      end
    end
  end
end

