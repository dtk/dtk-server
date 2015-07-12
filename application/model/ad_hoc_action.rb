# TODO: Marked for removal [Haris]
module DTK
  class AdHocAction
    def initialize(assembly, opts = {})
      @assembly      = assembly
      @component     = opts[:component]
      @method_name   = opts[:method_name]
      @action_params = opts[:action_params]
    end
    def self.generate_template_content(assembly, opts = {})
      new(assembly, opts).generate_template_content()
    end
    def generate_template_content
      Task::Template::Content.parse_and_reify(serialized_content(), get_config_components())
    end

    def get_config_components
      # TODO: for efficiency, can prune using  @component when it is non null
      opts_action_list = {}
      Task::Template::ActionList::ConfigComponents.get(@assembly, opts_action_list)
    end

    private

    def serialized_content
        #TODO: stub
        { subtask_order: 'sequential',
          subtasks:           [{
             name: 'component bigpetstore::spark_app[spark-1.3.1]',
             node: 'client',
             ordered_components: ['bigpetstore::spark_app[spark-1.3.1]']
           },
                               { name: 'run app bigpetstore::spark_app[spark-1.3.1]',
                                 node: 'client',
                                 actions: ['bigpetstore::spark_app[spark-1.3.1].run_app']
                               }]
        }
    end
  end
end
