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

      def method_missing(name,*args,&block)
        @action.send(name,*args,&block)
      end
      def respond_to?(name)
        @action.espond_to?(name) || super
      end
    end
  end
end; end
