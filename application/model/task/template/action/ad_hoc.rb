module DTK; class Task; class Template
  class Action
    module AdHoc
      # opts can have
      #  :method_name
      def self.ret_action(assembly,component,opts={})
        augmented_cmp = component.merge(:node => component.get_node())
        if title = component.has_title?()
          augmented_cmp.merge!(:title => title)
        end
        
        opts_create = Hash.new
        if action_def = get_action_def?(component,opts)
          opts_create.merge!(:action_def => action_def)
        end             

        Action.create(augmented_cmp,opts_create)
      end
      
      def self.list(assembly)
        ret = Array.new
        config_components = ActionList::ConfigComponents.get(assembly)
        config_components.each do |config_component|
          add_non_dups!(ret,actions_pretty_print_form(config_component))
        end
        ret
      end
      
     private
      def self.get_action_def?(component,opts={})
        if method_name = opts[:method_name]
          component.get_action_def?(method_name,:cols => [:id,:group_id,:method_name]) ||
            raise(ErrorUsage.new("Method '#{method_name}' is not defined on component '#{component.display_name_print_form()}'"))
        end
      end

      def self.actions_pretty_print_form(config_component)
        component_name = config_component.display_name_print_form
        config_component.action_defs().map do |action_def|
          {
            :component_name => component_name,
            :method_name    => action_def.get_field?(:method_name)
          }
        end
      end
     
      def self.add_non_dups!(ret,new_els)
        new_els.each do |new_el|
          unless ret.find{|r|r[:component_name] == new_el[:component_name] and r[:method_name] == new_el[:method_name]}
            ret << new_el
          end
        end
        ret
      end
    end
  end
end; end; end
