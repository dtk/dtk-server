module DTK; class ComponentDSL
  class ObjectModelForm
    class ParsingError < ErrorUsage
      def initialize(msg='',*args)
        super("component dsl parsing error: #{msg_pp_form(msg,*args)}",:caller_info => true)
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
      def msg_pp_form(msg,*args)
        args.each_with_index do |arg, i|
          if arg.kind_of?(Params)
            #make sure that params is at end
            unless i == (args.size-1)
              raise Error.new("The params arg must be last paramter")
            end
            arg.substitute!(msg)
          else
            msg.gsub!(Regexp.new("\\?#{(i+1).to_s}"),pp_format_arg(arg))
          end
        end
        msg
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
          raise Error.new("write param parsing")
        end
      end
    end
  end
end; end

