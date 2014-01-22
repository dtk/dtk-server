module DTK; class ComponentDSL
  class ObjectModelForm
    class ParsingError < ErrorUsage
      def initialize(msg='',*args)
        parsing_error,@params = msg_pp_form_and_params(msg,*args)
        super("component dsl parsing error: #{parsing_error}",:caller_info => true)
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
      #returns [parsing_error,params]
      def msg_pp_form_and_params(msg,*args)
        params = nil
        args.each_with_index do |arg, i|
          if arg.kind_of?(Params)
            #make sure that params is at end
            unless i == (args.size-1)
              raise Error.new("The params arg must be last paramter")
            end
            params = arg
            params.substitute!(msg)
          else
            msg.gsub!(substitute_num_regexp(i+1),pp_format_arg(arg))
          end
        end
        if any_free_vars?(msg)
          Log.error("The following error measgs has free variable(s): #{msg}")
        end
        [msg,params]
      end

      module CommonMix
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

        def substitute_num_regexp(num)
          Regexp.new("\\?#{num.to_s}")
        end
        def substitute_param_regexp(param)
          Regexp.new("\\?#{param}")
        end
        def any_free_vars?(msg)
          msg =~ /\?[0-9a-z]+/
        end
      end

      include CommonMix

      class MissingKey < self
        def initialize(key)
          super("missing key (#{key})")
        end
      end

      class Params < Hash
      include CommonMix
        def initialize(hash={})
          super()
          replace(hash)
        end
        def substitute!(msg)
          each_pair{|param,val|msg.gsub!(substitute_param_regexp(param),val)}
          msg
        end
      end
    end
  end
end; end

