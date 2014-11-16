module DTK; class AttributeLink
  class Function 
    # base must go before base functions
    r8_nested_require('function','base')
    r8_nested_require('function','eq')
    r8_nested_require('function','eq_indexed')
    r8_nested_require('function','array_append')

    # hash_function must go before hash_function functions
    r8_nested_require('function','hash_function')
    r8_nested_require('function','composite')
    r8_nested_require('function','var_embedded_in_text')

    include Propagate::Mixin 
    def initialize(function_def,propagate_proc)
      @function_def = function_def
      # TODO: temp until we get rid of propagate_proc
      @index_map    = propagate_proc.index_map
      @attr_link_id = propagate_proc.attr_link_id
      @input_attr   = propagate_proc.input_attr
      @output_attr  = propagate_proc.output_attr
      @input_path   = propagate_proc.input_path
      @output_path  = propagate_proc.output_path
    end

    def self.link_function(link_info,input_attr,output_attr)
      ret = outer_fn = Base.base_link_function(input_attr,output_attr)
      if link_info.kind_of?(LinkDefLink::AttributeMapping::AugmentedLink)
        if fn_based_on_mapping = link_info.link_function?(outer_fn)
          ret = fn_based_on_mapping
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
      @function_class_names = [Eq,EqIndexed,ArrayAppend,VarEmbeddedInText]
    end
    def self.name()
      Aux.underscore(self.to_s).split('/').last.to_sym
    end
    def self.scalar_function_name?(function_def)
      function_def.kind_of?(String) && function_def.to_sym
    end
    
    def self.function_name(function_def)
      scalar_function_name?(function_def) || HashFunction.hash_function_name?(function_def) ||
        raise(Error.new("Function def has illegal form: #{function_def.inspect}"))
    end


  end
end; end

