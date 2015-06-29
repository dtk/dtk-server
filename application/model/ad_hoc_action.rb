module DTK
  class AdHocAction 
    def initialize(assembly,opts={})
      @assembly      = assembly
      @component     = opts[:component]
      @method_name   = opts[:method_name]
    end
    def self.component_action(assembly,component,opts={})
      new(assembly,opts.merge(:component => component)).component_action()
    end
    def component_action()
      augmented_cmp = component().merge(:node => @component.get_node())
      if title = component().has_title?()
        augmented_cmp.merge!(:title => title)
      end
      if action_def = get_action_def?()
        augmented_cmp.merge!(:action_def => action_def)
      end             
      Task::Template::Action.create(augmented_cmp)
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
    def component()
      @component || raise(Error.new("@component should be set"))
    end

    def get_action_def?()
      if @method_name
        component().get_action_def?(@method_name,:cols => [:id,:group_id,:method_name]) ||
          raise(ErrorUsage.new("Method '#{@method_name}' is not defined on component '#{component().display_name_print_form}'"))
      end
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

