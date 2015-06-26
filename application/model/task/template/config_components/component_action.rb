module DTK; class Task; class Template
  class ConfigComponents
    class ComponentAction 
      def initialize(assembly,component_idh,opts)
        @assembly = assembly
        @component = component_idh.create_object()
        @method_name = opts[:method_name]
        @action_params = opts[:action_params]
      end
      def self.generate_template_content(assembly,component_idh,opts={})
        new(assembly,component_idh,opts).generate_template_content()
      end
      def generate_template_content()
        # TODO: prune cmp_actions using component_idh
        opts_action_list = Hash.new
        cmp_actions = ActionList::ConfigComponents.get(@assembly,opts_action_list)
        Content.parse_and_reify(serialized_content(),cmp_actions)
      end

      def self.list(assembly)
        #TODO: stub
        nil
      end

      private
      def serialized_content()
        #TODO: stub
        {:subtask_order=>"sequential",
          :subtasks=>
          [{
             :name=>"component bigpetstore::spark_app[spark-1.3.1]",
             :node=>"client",
             :ordered_components=>["bigpetstore::spark_app[spark-1.3.1]"]
           },
           {:name=>"run app bigpetstore::spark_app[spark-1.3.1]",
             :node=>"client",
             :actions=>["bigpetstore::spark_app[spark-1.3.1].run_app"]
           }]
        }
      end
    end
  end
end; end; end
