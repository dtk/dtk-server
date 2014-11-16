module DTK; class AttributeLink
  class Function 
    # hash_function must go first
    r8_nested_require('function','hash_function')
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
    
    def self.scalar_function?(function_def,function_name=nil)
      scalar_function_name?(function_def) and 
        (function_name.nil? or function_name(function_def) == function_name)
    end
    def self.internal_hash_form?(function_def,propagate_proc)
      fn_name = function_name(function_def)
      fn_klass = function_class_names().find{|k|k.name() == fn_name}
      fn_klass && fn_klass.new(function_def,propagate_proc).internal_hash_form()
    end

   private
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


    class Eq < self
      def internal_hash_form()
        Output.new(:value_derived => output_value_aux())
      end
    end
    
    class EqIndexed < self
      # called when it is an equlaity setting between indexed values on input and output side. Can be the null index on one of the sides meaning to take whole value
      # TODO: can simplify because only will be called when input is not an array
      def internal_hash_form()
        if @index_map.nil? and (@input_path.nil? or @input_path.empty?) and (@output_path.nil? or @output_path.empty?)
          new_rows = output_value().nil? ? [nil] : (output_semantic_type().is_array? ?  output_value() : [output_value()])
          OutputArrayAppend.new(:array_slice => new_rows, :attr_link_id => @attr_link_id)
        else
          index_map_persisted = @index_map ? true : false
          index_map = @index_map || IndexMap.generate_from_paths(@input_path,@output_path)
          OutputPartial.new(:attr_link_id => @attr_link_id, :output_value => output_value, :index_map => index_map, :index_map_persisted => index_map_persisted)
        end
      end
    end

    class ArrayAppend < self
      # called when input is an array and each link into it appends teh value in
      def internal_hash_form()
        if @index_map.nil? and (@input_path.nil? or @input_path.empty?)
          new_rows = output_value().nil? ? [nil] : (output_semantic_type().is_array? ?  output_value() : [output_value()])
          output_is_array = @output_attr[:semantic_type_object].is_array?()
          OutputArrayAppend.new(:array_slice => new_rows, :attr_link_id => @attr_link_id, :output_is_array => output_is_array)
        else
          index_map_persisted = @index_map ? true : false
          index_map = @index_map || AttributeLink::IndexMap.generate_from_paths(@input_path,nil)
          OutputPartial.new(:attr_link_id => @attr_link_id, :output_value => output_value, :index_map => index_map, :index_map_persisted => index_map_persisted)
        end
      end
      
    end
  end
end; end

