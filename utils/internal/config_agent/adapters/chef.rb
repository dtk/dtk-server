module XYZ
  module ConfigAgentAdapter
    class Chef < ConfigAgent
      def ret_msg_content(node_actions)
        {:run_list => recipes(node_actions).map{|r|"recipe[#{r}]"}}
      end

      def recipes(node_actions)
        [node_actions].flatten.map do |a|
          ((a[:component]||{})[:external_ref]||{})[:recipe_name]
        end.compact.uniq
      end
    end
  end
end
