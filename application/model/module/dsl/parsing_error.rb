module DTK
  module ModuleDSL
    class ParsingError < ErrorUsage::DSLParsing
      r8_nested_require('parsing_error','params')
      #args as last arguments, can have
      # ...Params,Opts
      # ...Params
      # ...Opts
      # ..
      def initialize(msg='',*args)
        parsing_error,@params,opts = msg_pp_form_and_params(msg,*args)
        if error_prefix = opts.delete(:error_prefix)
          parsing_error = "#{error_prefix}: #{parsing_error}"
        end

       #TODO: cleanup so parent takes opts, rather than opts_or_file_path
        opts_or_file_path =
          if opts.empty?
            {:caller_info=>true}
          elsif opts[:file_path]
            if opts.size > 1
              raise Error.new("Not supported yet, need to cleanup so parent takes opts, rather than opts file path")
            else
              opts[:file_path]
            end
          else
            opts
          end
        super(parsing_error,opts_or_file_path)
      end

      def self.raise_error_if_not(obj,klass,opts={})
        unless obj.kind_of?(klass)
          fragment_type = opts[:type]||'fragment'
          for_text = (opts[:for] ? " for #{opts[:for]}" : nil)
          err_msg = "Ill-formed #{fragment_type} (?obj)#{for_text}; it should be a #{klass}"
          err_params = Params.new(:obj => obj)
          if context = opts[:context]
            err_msg << "; it appears in ?context"
            err_params.merge!(:context => context)
          end
          raise new(err_msg,err_params)
        end
      end

      def self.raise_error_if_value_nil(k,v)
        if v.nil?
          raise new("Value of (?1) should not be nil",k)
        end
      end

      def self.trap(&block)
        ret = nil
        begin
          ret = yield
        rescue ErrorUsage::DSLParsing,ErrorUsage::Parsing => e
          ret = e
        end
        ret
      end

      def self.is_error?(obj)
        obj.is_a?(ErrorUsage::DSLParsing) || 
        obj.is_a?(ErrorUsage::Parsing)
      end

     private
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

      def self.create_with_hash_params(msg,hash_params,*args)
        new(msg,*Params.add_to_array(args,hash_params))
      end

      #returns [parsing_error,params,opts]
      def msg_pp_form_and_params(msg_x,*args)
        msg = msg_x.dup
        params = nil
        opts = Opts.new
        args.each_with_index do |arg, i|
          if arg.kind_of?(Params)
            #make sure that params,opts are at end
            unless i == (args.size-1) or i == (args.size-2)
              raise Error.new("Args of type (#{arg.class}) must be one of last two args")
            end
            params = arg
            substitute_params!(msg,params)
          elsif arg.kind_of?(Opts)
             unless i == (args.size-1)
               raise Error.new("Args of type (#{arg.class}) must be end")
             end
            opts = arg
          else
            substitute_num!(msg,i+1,arg)
          end
        end
        if free_var = any_free_vars?(msg)
          Log.error("The following error message has free variable: #{free_var}")
        end
        [msg,params,opts]
      end

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
    end
  end
end
