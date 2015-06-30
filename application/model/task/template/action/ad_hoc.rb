module DTK; class Task; class Template
  class Action
    class AdHoc
      # opts can have
      #  :method_name
      def initialize(assembly,component,opts={})
        @assembly              = assembly
        @component             = component
        @method_name           = opts[:method_name]
        @task_template_content = ret_task_template_content()
      end

      attr_reader :task_template_content

      def task_action_name()
        ret = component_name()
        if @method_name
          ret << ".#{@method_name}"
        end
        ret
      end

      def self.list(assembly)
        ret = Array.new
        action_list = get_action_list(assembly)
        action_list.each do |component_action|
          add_non_dups!(ret,action_pretty_print_form(component_action))
        end
        ret
      end
      
     private
      def get_action_list()
        self.class.get_action_list(@assembly)
      end
      def self.get_action_list(assembly)
        ActionList::ConfigComponents.get(assembly)
      end

      def ret_task_template_content()
        action_list = get_action_list()
        Content.parse_and_reify(serialized_content(),action_list)
      end

      def serialized_content()
        ret = {:node => @component.get_node().get_field?(:display_name)}
        ret.merge(@method_name ? with_method_name() : without_method_name())
      end

      # TODO: encapsulate the delimeters with parsing routines
      def without_method_name()
        {:components => [component_name()]}
      end
      def with_method_name()
        {:actions => ["#{component_name()}.#{@method_name}"]}
      end
      def component_name()
        ret = @component.display_name_print_form()
        if title = @component.has_title?()
          ret << "[#{title}]"
        end
        ret
      end

      def self.action_pretty_print_form(component_action)
        component_name = component_action.display_name_print_form
        component_action.action_defs().map do |action_def|
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
