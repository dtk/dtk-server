module DTK
 class ComponentDSL
    class ParsingError < Module::ParsingError
      r8_nested_require('parsing_error','ref_component_templates')
      r8_nested_require('parsing_error','link_def')
      r8_nested_require('parsing_error','dependency')
      r8_nested_require('parsing_error','missing_key')

      def initialize(msg='',*args)
        parsing_error,@params = msg_pp_form_and_params(msg,*args)
        super("Component dsl parsing error: #{parsing_error}",:caller_info => true)
      end

      def self.raise_error_if_not(obj,klass,opts={})
        unless obj.kind_of?(klass)
          fragment_type = opts[:type]||'fragment'
          for_text = (opts[:for] ? " for #{opts[:for]}" : nil)
          raise new("Ill-formed #{fragment_type} (?1)#{for_text}; it should be a #{klass}",obj)
        end
      end

      def self.raise_error_if_value_nil(k,v)
        if v.nil?
          raise new("Value of (?1) should not be nil",k)
        end
      end

     private 
      def self.create_with_hash_params(msg,hash_params,*args)
        new(msg,*Params.add_to_array(args,hash_params))
      end

      #returns [parsing_error,params]
      def msg_pp_form_and_params(msg_x,*args)
        msg = msg_x.dup
        params = nil
        args.each_with_index do |arg, i|
          if arg.kind_of?(Params)
            #make sure that params is at end
            unless i == (args.size-1)
              raise Error.new("The params arg must be last paramter")
            end
            params = arg
            substitute_params!(msg,params)
          else
            substitute_num!(msg,i+1,arg)
          end
        end
        Log.info("Parsing error: #{self.class}")
        if free_var = any_free_vars?(msg)
          Log.error("The following error message has free variable: #{free_var}")
        end
        [msg,params]
      end

      def pp_format_arg(arg)
        if arg.kind_of?(Array) or arg.kind_of?(Hash)
          format_type = DefaultNonScalarFormatType
          "\n\n#{Aux.serialize(arg,format_type)}"
        elsif arg.kind_of?(String)
          arg
        elsif arg.kind_of?(TrueClass) or arg.kind_of?(FalseClass) or arg.kind_of?(Fixnum) or arg.kind_of?(Symbol)
          arg.to_s
        else      
          arg.inspect
        end
      end
      DefaultNonScalarFormatType = :yaml

      def substitute_num!(msg,num,arg)
        msg.gsub!(substitute_num_regexp(num),pp_format_arg(arg))
      end
      def substitute_params!(msg,params)
        params.each_pair do |param,val|
          msg.gsub!(substitute_param_regexp(param),pp_format_arg(val))
        end
        msg
      end

      def substitute_num_regexp(num)
        Regexp.new("\\?#{num.to_s}")
      end
      def substitute_param_regexp(param)
        Regexp.new("\\?#{param}")
      end
      def any_free_vars?(msg)
        #only finds first free variable
        if msg =~ Regexp.new("(\\?[0-9a-z]+)")
          $1
        end
      end

      class Params < Hash
        def initialize(hash={})
          super()
          replace(hash)
        end

        #array can have as last element a Params arg
        def self.add_to_array(array,hash_params)
          if array.last().kind_of?(Params)
            array[0...array.size-1] + [array.last().dup.merge(hash_params)]
          else
            array + [new(hash_params)]
          end
        end

      end
    end
  end
end


