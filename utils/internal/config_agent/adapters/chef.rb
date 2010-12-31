module XYZ
  module ConfigAgentAdapter
    class Chef < ConfigAgent
      Lock = Mutex.new
      def ret_msg_content(node_actions)
Lock.synchronize do
pp [:recipes_and_attributes, recipes_and_attributes(node_actions)]
end
        {:run_list => recipes(node_actions).map{|r|"recipe[#{r}]"}}        
      end

      def recipes(node_actions)
        ret = Array.new
        node_actions.elements.each  do |a|
          rcp = ((a[:component]||{})[:external_ref]||{})[:recipe_name]
          ret << rcp if rcp and not ret.include?(rcp)
        end
        ret
        #TODO: strange shat may be ruby parsing or garbage collection error 
        #which causes error when below is used instead of above
        #node_actions.elements.map do |a|
        #  ((a[:component]||{})[:external_ref]||{})[:recipe_name]
        #end.compact.uniq
      end

      def recipes_and_attributes(node_actions)
        node_actions.elements.inject(ChefNodeActions.new()){|ret,action|ret.add_action(action)}
      end
     private

      class ChefNodeActions 
        def initialize()
          @recipes = Array.new
          @common_attr_index = Hash.new
          @attributes = Hash.new
        end
        def add_action(action)
          recipe_name = recipe(action)
          if @common_attr_index[recipe_name]
            common_attr_val_list = @common_attr_index[recipe_name]
            common_attr_val_list << attributes(action, :strip_off_recipe_name => true)
          elsif action[:component][:only_one_per_node]
            @recipes << recipe_name
            @attributes.merge!(attributes(action))
          else
            @recipes << recipe_name
            list = Array.new
            @common_attr_index[recipe_name] = list
            list << attributes(action, :strip_off_recipe_name => true)
            @attributes.merge!(recipe_name => {"list" => list})
          end
          self
        end
       private
        def recipe(action)
          ((action[:component]||{})[:external_ref]||{})[:recipe_name]
        end
        def attributes(action,opts={})
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
