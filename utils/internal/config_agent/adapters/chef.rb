module XYZ
  module ConfigAgentAdapter
    class Chef < ConfigAgent
      def ret_msg_content(node_actions)
        recipes_and_attrs = recipes_and_attributes(node_actions)
        {:attributes => recipes_and_attrs.attributes, :run_list => recipes_and_attrs.run_list}
      end
     private
      def recipes_and_attributes(node_actions)
        node_actions.elements.inject(ChefNodeActions.new()){|ret,action|ret.add_action(action)}
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

        def add_action(action)
          recipe_name = recipe(action)
          if @common_attr_index[recipe_name]
            common_attr_val_list = @common_attr_index[recipe_name]
            common_attr_val_list << ret_attributes(action, :strip_off_recipe_name => true)
          elsif action[:component][:only_one_per_node]
            @recipe_names << recipe_name
            @attributes.merge!(ret_attributes(action))
          else
            @recipe_names << recipe_name
            list = Array.new
            @common_attr_index[recipe_name] = list
            list << ret_attributes(action, :strip_off_recipe_name => true)
            @attributes.merge!(recipe_name => {"list" => list})
          end
          self
        end
       private
        def recipe(action)
          ((action[:component]||{})[:external_ref]||{})[:recipe_name]
        end
        def ret_attributes(action,opts={})
          ret = Hash.new
          (action[:attributes]||[]).each do |attr|
            var_name_path = (attr[:external_ref]||{})[:path]
            val = attr[:attribute_value]
            #TODO: after testing remove nils
            ret.merge!(attribute_name(var_name_path,opts) => val) if var_name_path
          end.compact
          ret
        end
        def attribute_name(var_name_path,opts={})
          #TODO: assume form is node[recipe][x1] or node[recipe][x1][x2] or ..
          reverse_keys = var_name_path.gsub(/^node\[/,"").gsub(/\]$/,"").split("][").reverse
          reverse_keys.pop if opts[:strip_off_recipe_name]
          f = reverse_keys.shift
          reverse_keys.inject(f){|h,k|{k => h}}
        end
      end
    end
  end
end
