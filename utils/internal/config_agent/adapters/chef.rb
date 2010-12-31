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
          @attributes = Array.new
        end
        def add_action(action)
          component_id = action[:component][:id]
          if @common_attr_index[component_id]
            common_attr_val_list = @common_attr_index[component_id]
            common_attr_val_list << attributes(action)
          elsif action[:component][:only_one_per_node]
            @recipes << recipe(action)
            @attributes += attributes(action)
          else
            @recipes << recipe(action)
            list = Array.new
            @common_attr_index[component_id] = list
            list << attributes(action)
            @attributes << {:list => list}
          end
        end
       private
        def recipe(action)
          ((action[:component]||{})[:external_ref]||{})[:recipe_name]
        end
        def attributes(action)
          (action[:attributes]||[]). map do |attr|
            key = (attr[:external_ref]||{})[:path]
            val = attr[:attribute_value]
            #TODO: after testing remove nils
            {key => val} if key
          end.compact
        end
      end
    end
  end
end
