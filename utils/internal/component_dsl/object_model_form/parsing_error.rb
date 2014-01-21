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

      def msg_pp_form(msg,*args)
        args.each_with_index do |arg, i|
          msg.gsub!(Regexp.new("\\?#{(i+1).to_s}"),pp_format_arg(arg))
        end
        msg
      end
      def pp_format_arg(arg)
        #TODO: hard-coded format
        format_type = :json
        if format_type == :json 
          if arg.kind_of?(Hash)
            JSON.generate(arg)
          else
            arg.inspect
          end
        else
          arg.inspect
        end
      end
      private :msg_pp_form, :pp_format_arg

      class MissingKey < self
        def initialize(key)
          super("missing key (#{key})")
        end
      end
    end
  end
end; end

