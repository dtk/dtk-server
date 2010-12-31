module XYZ
  module ConfigAgentAdapter
    class Chef < ConfigAgent
      def ret_msg_content(node_actions)
        {:run_list => recipes(node_actions).map{|r|"recipe[#{r}]"}}        
      end

      def recipes(node_actions)
        ret = Array.new
        node_actions.elements.each  do |a|
          rcp = ((a[:component]||{})[:external_ref]||{})[:recipe_name]
          ret << rcp if rcp
        end
        ret
        #TODO: strange shat may be ruby parsing or garbage collection error 
        #which causes error when below is used instead of above
        #node_actions.elements.map do |a|
        #  ((a[:component]||{})[:external_ref]||{})[:recipe_name]
        #end.compact
      end
    end
  end
end
