module DTK
  class AdHocAction 
    def initialize(assembly,opts={})
      @assembly      = assembly
      @component     = opts[:component]
      @method_name   = opts[:method_name]
    end
    def self.get_action(assembly,component,opts={})
      new(assembly,opts.merge(:component => component)).get_action()
    end
    def get_action()
#      Action.create(new_component.merge(:node => node,:title => component_title))
# TODO add 
      Task::Template::Action.create(@component.merge(:node => @component.get_node()))
    end

    def self.list(assembly)
      new(assembly).list()
    end

    def list()
      ret = Array.new
      config_components = Task::Template::ActionList::ConfigComponents.get(@assembly)
      config_components.each do |config_component|
        add_non_dups!(ret,actions_pretty_print_form(config_component))
      end
      ret
    end

   private
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

