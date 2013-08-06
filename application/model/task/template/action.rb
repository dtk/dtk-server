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
      def node_id()
        (component[:node]||{})[:id]
      end

      def serialization_form()
        cmp =  component()
        node_name = cmp[:node][:display_name]
        cmp_name = Component.component_type_print_form(cmp[:component_type])
        if title = cmp[:title]
          cmp_name = ComponentTitle.print_form_with_title(cmp_name,title)
        end
        "#{node_name}/#{cmp_name}"          
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
