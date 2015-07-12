module DTK; class ErrorUsage
  class Parsing
    class Params < Hash
      def initialize(hash = {})
        super()
        replace(hash)
      end

      # array can have as last element a Params arg
      def self.add_to_array(array, hash_params)
        if array.last().is_a?(Params)
          array[0...array.size - 1] + [array.last().dup.merge(hash_params)]
        else
          array + [new(hash_params)]
        end
      end
      # TODO: collapse these two
      def self.add_opts(args_x, opts)
        base_opts = (opts.is_a?(Opts) ? opts : Opts.new(opts))
        if args_x.last.is_a?(Opts)
          args[0...-1] + [base_opts.merge(args.last)]
        else
          args_x + [base_opts]
        end
      end

      # returns [parsing_error,params,opts]
      def self.process(raw_msg, *args)
        processed_msg = raw_msg.dup
        params = nil
        opts = Opts.new

        args.each_with_index do |arg, i|
          if arg.is_a?(Params)
            # make sure that params,opts are at end
            unless i == (args.size - 1) || i == (args.size - 2)
              fail Error.new("Args of type (#{arg.class}) must be one of last two args")
            end
            params = arg
            substitute_params!(processed_msg, params)
          elsif arg.is_a?(Opts)
            unless i == (args.size - 1)
              fail Error.new("Args of type (#{arg.class}) must be end")
            end
            opts = arg
          else
            substitute_num!(processed_msg, i + 1, arg)
          end
        end
        [processed_msg, params, opts]
      end

      def self.substitute_file_path?(msg, file_path)
        ret = !!(msg =~ Regexp.new("\\?#{FilePathFreeVar}"))
        file_path_msg = "(in file #{file_path})"
        substitute_params!(msg, FilePathFreeVar => file_path_msg)
        ret
      end
      FilePathFreeVar = 'file_path'

      def self.any_free_vars?(msg)
        # only finds first free variable
        if msg =~ FreeVariable
          Regexp.last_match(1)
        end
      end
      FreeVariable = Regexp.new('(\\?[0-9a-z_]+)')

      private

      def self.substitute_num!(msg, num, arg)
        msg.gsub!(substitute_num_regexp(num), pp_format_arg(arg))
      end

      def self.substitute_params!(msg, params)
        params.each_pair do |param, val|
          msg.gsub!(substitute_param_regexp(param), pp_format_arg(val))
        end
        msg
      end

      def self.pp_format_arg(arg)
        if arg.is_a?(Array) || arg.is_a?(Hash)
          format_type = DefaultNonScalarFormatType
          "\n\n#{Aux.serialize(arg, format_type)}"
        elsif arg.is_a?(String)
          arg
        elsif arg.is_a?(TrueClass) || arg.is_a?(FalseClass) || arg.is_a?(Fixnum) || arg.is_a?(Symbol)
          arg.to_s
        else
          arg.inspect
        end
      end
      DefaultNonScalarFormatType = :yaml


      def self.substitute_num_regexp(num)
        Regexp.new("\\?#{num}")
      end
      def self.substitute_param_regexp(param)
        Regexp.new("\\?#{param}")
      end

      def self.file_path_free_var?(msg)
        !!(msg =~ FilePathFreeVar)
      end
    end
  end
end; end
