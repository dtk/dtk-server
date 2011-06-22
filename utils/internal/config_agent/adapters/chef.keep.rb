module XYZ
  module ConfigAgentAdapter
    class Chef < ConfigAgent
      def ret_msg_content(config_node)
        recipes_and_attrs = recipes_and_attributes(config_node)
        {:attributes => recipes_and_attrs.attributes, :run_list => recipes_and_attrs.run_list}
      end
      def type()
        :chef
      end
     private
      def recipes_and_attributes(config_node)
        config_node[:component_actions].inject(ChefNodeActions.new()){|ret,component_action|ret.add_action(component_action)}
      end

      class ChefNodeActions 
        attr_reader :attributes
        def initialize()
          @recipe_names = Array.new
          @common_attr_index = Hash.new
          @attributes = Hash.new
        end

        def run_list()
          @recipe_names.map{|r|"recipe[#{r}]"}
        end

        def add_action(component_action)
          recipe_name = recipe(component_action)
          if @common_attr_index[recipe_name]
            common_attr_val_list = @common_attr_index[recipe_name]
            common_attr_val_list << ret_attributes(component_action, :strip_off_recipe_name => true)
          elsif component_action[:component][:only_one_per_node]
            @recipe_names << recipe_name
            deep_merge!(@attributes,ret_attributes(component_action))
          else
            @recipe_names << recipe_name
            list = Array.new
            @common_attr_index[recipe_name] = list
            list << ret_attributes(component_action, :strip_off_recipe_name => true)
            if recipe_name =~ /(^.+)::(.+$)/
              cookbook_name = $1
              rcp_name = $2
              deep_merge!(@attributes,{cookbook_name => {rcp_name => {"!replace:list" => list}}})
            else
              deep_merge!(@attributes,{recipe_name => {"!replace:list" => list}})
            end
          end
          self
        end
       private
        def deep_merge!(target,source)
          source.each do |k,v|
            if target.has_key?(k)
              deep_merge!(target[k],v)
            else
              target[k] = v
            end
          end
        end

        def recipe(action)
          ((action[:component]||{})[:external_ref]||{})[:recipe_name]
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
          #TODO: assume form is node[recipe][x1] or node[recipe][x1][x2] or ..
          #service[recipe][x1] or service[recipe][x1][x2] or ..
        def to_array_form(external_ref_path,opts)
          #TODO: use regexp disjunction
          ret = external_ref_path.gsub(/^node\[/,"").gsub(/^service\[/,"").gsub(/\]$/,"").split("][")
          ret.shift if opts[:strip_off_recipe_name]
          ret
        end
      end
    end
  end
end
