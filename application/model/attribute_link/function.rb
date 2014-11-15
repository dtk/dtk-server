module DTK; class AttributeLink
  class Function 
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
    def self.hash_function_name?(function_def)
      if function_def.kind_of?(Hash) and function.has_key?(:function)
        (function[:function]||{})[:name]
      end
    end
    def self.function_name(function_def)
      scalar_function_name?(function_def) || hash_function_name?(function_def) ||
        raise(Error.new("Function def has illegal form: #{function_def.inspect}"))
    end

    class Eq < self
      def self.isa?(function)
        scalar_function?(function,:eq)
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

    #TODO: update so deals with different forms other than :eq
    class VarEmbeddedInText < self
      def initialize(function_def,propagate_proc)
        super
        unless @text_parts = (@function_def[:constants]||{})[:text_parts]
          raise Error.new("function_def[:constants]:text_parts] is missing")
        end
      end

      def self.function_def(text_parts)
        {
          :name => name(),
          :constants => {:text_parts => text_parts}
        }
      end
      def self.internal_hash_form()
        val = nil
        valurn val if param.nil?
        
        text_parts = @function_def.dup
        val = text_parts.shift
        text_parts.each do |text_part|
          val << param
          val << text_part
        end
        val && {:value_derived => val} 
      end
    end

  end
end; end
