module DTK; class AttributeLink
  class Function 
    # base must go before its children
    r8_nested_require('function','base')
    r8_nested_require('function','eq')
    r8_nested_require('function','eq_indexed')
    r8_nested_require('function','array_append')

    # with_args must go before its children
    r8_nested_require('function','with_args')
    r8_nested_require('function','composite')
    r8_nested_require('function','var_embedded_in_text')

    include Propagate::Mixin 
    def initialize(function_def,propagate_proc)
      # TODO: temp until we get rid of propagate_proc
      @index_map    = propagate_proc.index_map
      @attr_link_id = propagate_proc.attr_link_id
      @input_attr   = propagate_proc.input_attr
      @output_attr  = propagate_proc.output_attr
      @input_path   = propagate_proc.input_path
      @output_path  = propagate_proc.output_path
    end

    def self.link_function(link_info,input_attr,output_attr)
      ret = base_fn = Base.base_link_function(input_attr,output_attr)
      if link_info.respond_to?(:parse_function_with_args?)
        if parse_info = link_info.parse_function_with_args?()
          ret = WithArgs.with_args_link_function(base_fn,parse_info)
        end
      end
      ret
    end

    def internal_hash_form(opts={})
      raise Error.new("Should not be called")
    end

    def value(opts={})
      raise Error.new("Should not be called")
    end
    
   private
    def self.scalar_function?(function_def,function_name=nil)
      scalar_function_name?(function_def) and 
        (function_name.nil? or function_name(function_def) == function_name)
    end

    def self.internal_hash_form?(function_def,propagate_proc)
      fn_name = function_name(function_def)
      fn_klass = function_class_names().find{|k|k.name() == fn_name}
      fn_klass && fn_klass.new(function_def,propagate_proc).internal_hash_form()
    end

    def self.function_class_names()
      @function_class_names = [Eq,EqIndexed,ArrayAppend,Composite,VarEmbeddedInText]
    end
    
    def self.klass(name)
      begin
        const_get(Aux.camelize(name))
       rescue
        raise Error.new("Illegal function name (#{name}")
      end
    end

    def self.name()
      Aux.underscore(self.to_s).split('/').last.to_sym
    end
    
    def self.function_name(function_def)
     Base.function_name?(function_def) || WithArgs.function_name?(function_def) ||
        raise(Error.new("Function def has illegal form: #{function_def.inspect}"))
    end

  end
end; end

