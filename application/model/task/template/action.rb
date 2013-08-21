module DTK; class Task; class Template
  class Action
    def self.create(action)
      if action.kind_of?(Component)
        ComponentAction.new(action)
      else
        raise Error.new("Not yet implemented treatment of action of type {#{action.class.to_s})")
      end
    end

    attr_accessor :index

    def method_missing(name,*args,&block)
      @action.send(name,*args,&block)
    end
    def respond_to?(name)
      @action.respond_to?(name) || super
    end

   private
    def initialize(action)
      @action = action
      @index = nil
    end

    class ComponentAction < self
      def node()
        component[:node]
      end
      def node_id()
        (node()||{})[:id]
      end
      def node_name()
        (node()||{})[:display_name]
      end

      def match?(node_name,component_name_ref=nil)
         ret = 
          if node_name() == node_name
            if component_name_ref.nil?
              true
            else
              #strip off node_name prefix if it exists
              component_name_ref_x = component_name_ref.split("/").last
              component_name_ref_x ==  serialization_form(:no_node_name_prefix => true)
            end
          end
        !!ret
      end

      def match_component_type?(component_type)
        component_type == component_type(:without_title=>true)
      end

      def serialization_form(opts={})
        if filter = opts[:filter]
          if filter.keys == [:source]
            return nil unless filter[:source] == source_type()
          else
            raise Error.new("Not treating filter of form (#{filter.inspect})")
          end
        end
        node_name = ((!opts[:no_node_name_prefix]) && component()[:node][:display_name])
        component_type = component_type()
        node_name ? "#{node_name}/#{component_type}" : component_type
      end
        
      def source_type()
        ret = (component()[:source]||{})[:type]
        ret && ret.to_sym
      end

      def assembly_idh?()
        if source_type() == :assembly
          component()[:source][:object].id_handle()
        end
      end

     private
      def component()
        @action
      end
      
      def component_type(opts={})
        cmp =  component()
        cmp_type = Component.component_type_print_form(cmp[:component_type])
        unless opts[:without_title] 
          if title = cmp[:title]
            cmp_type = ComponentTitle.print_form_with_title(cmp_type,title)
          end
        end
        cmp_type
      end

    end
  end
end; end; end
