module DTK; class Task; class Template
  class Action
    r8_nested_require('action','component_action')
    r8_nested_require('action','action_method')
    r8_nested_require('action','with_method')

    # opts can have keys
    # :index
    # :parent_action 
    attr_accessor :index
    def initialize(opts={})
      @index = opts[:index] || opts[:parent_action] && opts[:parent_action].index
    end
    private :initialize

    # opts can have keys
    # :method_name
    # :index
    # :parent_action 

    def self.create(object,opts={})
      if object.kind_of?(Component)
        add_action_method?(ComponentAction.new(object,opts),opts)
      elsif object.kind_of?(Action)
        add_action_method?(object,opts)
      else
        raise Error.new("Not yet implemented treatment of action of type {#{object.class.to_s})")
      end
    end

    def self.find_action_in_list?(serialized_item,node_name,action_list,opts={})
      # method_name could be nil
      component_name_ref,method_name = WithMethod.parse(serialized_item)
      if action = action_list.find_matching_action(node_name,:component_name_ref => component_name_ref)
        if cgn = opts[:component_group_num]
          action = action.in_component_group(cgn)
        end
        create(action,method_name ? {:method_name => method_name} : {})
      end
    end

    def method_missing(name,*args,&block)
      @action.send(name,*args,&block)
    end
    def respond_to?(name)
      @action.respond_to?(name) || super
    end

    # this can be overwritten
    def action_method?()
      nil
    end

   private
    def self.add_action_method?(base_action,opts={})
      opts[:method_name] ? base_action.class::WithMethod.new(base_action,opts) : base_action
    end
  end
end; end; end
