module DTK
  class AdHocAction 
    def initialize(assembly,opts={})
      @assembly      = assembly
      @component     = opts[:component]
      @method_name   = opts[:method_name]
      @action_params = opts[:action_params]
    end
    def self.action(assembly,opts={})
      new(assembly,opts).action()
    end
    def get_action()
      config_components = get_config_components()
      Action.create(new_component.merge(:node => node,:title => component_title))
    end

    def self.list(assembly)
      new(assembly).list()
    end

    def list()
      config_components = get_config_components()
      ret = Array.new
      config_components.each do |config_component|
        add_non_dups!(ret,actions_pretty_print_form(config_component))
      end
      ret
    end

   private
    def get_config_components()
      # TODO: for efficiency, can prune using @component when it is non null
      #       to implement this wil have to update ConfigComponents.get to take pruning option
      Task::Template::ActionList::ConfigComponents.get(@assembly)
    end

# TODO: OLD
    def serialized_content()
      {
        :subtask_order=>"sequential",
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

    def actions_pretty_print_form(config_component)
      component_name = config_component.display_name_print_form
      config_component.action_defs().map do |action_def|
        {
          :component_name => component_name,
          :method_name    => action_def.get_field?(:method_name)
        }
      end
    end
     
    def add_non_dups!(ret,new_els)
      new_els.each do |new_el|
        unless ret.find{|r|r[:component_name] == new_el[:component_name] and r[:method_name] == new_el[:method_name]}
          ret << new_el
        end
      end
      ret
    end

  end
end

