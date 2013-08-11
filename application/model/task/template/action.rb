module DTK; class Task; class Template
  class Action
    def self.create(action)
      if action.kind_of?(Component)
        ComponentAction.new(action)
      else
        raise Error.new("Not yet implemented treatment of action of type {#{action.class.to_s})")
      end
    end

    attr_writer :index
    def index()
      unless ret = @index
        raise Error.new("index() should not be called if @index hash not been set")
      end
      ret
    end

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

      def serialization_form(opts={})
        if filter = opts[:filter]
          if filter.keys == [:source]
            return nil unless filter[:source] == source_type()
          else
            raise Error.new("Not treating filter of form (#{filter.inspect})")
          end
        end
        cmp =  component()
        node_name = ((!opts[:no_node_name_prefix]) && cmp[:node][:display_name])
        cmp_name = Component.component_type_print_form(cmp[:component_type])
        if title = cmp[:title]
          cmp_name = ComponentTitle.print_form_with_title(cmp_name,title)
        end
        node_name ? "#{node_name}/#{cmp_name}" : cmp_name
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
    end
  end
end; end; end
