module DTK; class Task; 
  class Template
    class ActionList < Array
      r8_nested_require('action_list','config_components')
      def set_action_indexes!()
        each_with_index{|a,i|a.index = i}
        self
      end

      def <<(el)
        super(Action.new(el))
      end
    end
    
    #simple wrapper around elements passed as actions
    class Action
      def initialize(action)
        @action = action
        @index = nil
      end
      attr_writer :index
      def index()
        unless ret = @index
          raise Error.new("index() should not be called if @index hash not been set")
        end
        ret
      end

      def node_id()
        apply(NodeId)
      end

      def method_missing(name,*args,&block)
        @action.send(name,*args,&block)
      end
      def respond_to?(name)
        @action.respond_to?(name) || super
      end

      def serialization_form()
        apply(SerializationForm)
      end
     private
      def action_type()
        if @action.kind_of?(Component)
          :component_action
        else
          raise Error.new("Not yet implemented treatment of action of type {#{@action.class.to_s})")
        end
      end

      def apply(klass)
        klass.send(action_type(),@action)
      end
      class NodeId
        def self.component_action(cmp)
          cmp[:node] && cmp[:node][:id]
        end
      end
      class SerializationForm
        def self.component_action(cmp)
          node_name = cmp[:node][:display_name]
          cmp_name = Component.component_type_print_form(cmp[:component_type])
          if title = cmp[:title]
            cmp_name = ComponentTitle.print_form_with_title(cmp_name,title)
          end
        "#{node_name}/#{cmp_name}"
        end
      end
    end
  end
end; end
