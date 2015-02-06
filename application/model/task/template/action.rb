module DTK; class Task; class Template
  class Action
    r8_nested_require('action','component_action')
    r8_nested_require('action','with_method')

    # opts can have keys
    # :index
    # :parent_action 
    attr_accessor :index
    def initialize(opts={})
      @index = opts[:index] || opts[:parent_action] && opts[:parent_action].index
    end
    private :initialize

    def self.create(object,opts={})
      if object.kind_of?(Component)
        ComponentAction.new(object,opts)
      else
        raise Error.new("Not yet implemented treatment of action of type {#{object.class.to_s})")
      end
    end

    def method_missing(name,*args,&block)
      @action.send(name,*args,&block)
    end
    def respond_to?(name)
      @action.respond_to?(name) || super
    end
  end
end; end; end
