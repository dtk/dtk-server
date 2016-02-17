module DTK
  module CommandAndControlAdapter
    class Bosch < CommandAndControlIAAS

      def self.execute(_task_idh, _top_task_idh, task_action)
        puts "Execute!"
      end


    end
  end
end