module DTK
  class ConfigAgent
    class ParseErrorsCache < ErrorUsage
      def initialize(config_agent_type)
        @config_agent_type = config_agent_type
        # indexed by file_path
        @ndx_error_list = Hash.new
      end

      def add(obj,opts=Opts.new)
        if obj.kind_of?(ParseError)
          add_error(obj,opts)
        elsif obj.kind_of?(self.class)
          unless opts.empty?
            Log.error("Opts should be empty; it is set to: #{opts.inject}}")
          end
          add_errors(obj)
        else
          raise Error.new("Unexpected object type (#{obj.class})")
        end
        self
      end

      def create_error()
        msg = "\n"
        num_errs = 0
        @ndx_error_list.each_pair do |file_path,errors|
          ident = IdentInitial
          if file_path
            add_line!(msg,"In file #{file_path}:",ident)
            ident += IdentIncrease
          end
          errors.each do |error|
            num_errs += 1
            add_line!(msg,sentence_capitalize(error.to_s),ident)
          end
        end
        opts = Opts.new(:error_prefix => error_prefix(num_errs), :log_error => false)
        ErrorUsage::Parsing.new(msg,opts)
      end
      IdentInitial = 2
      IdentIncrease = 2

      attr_reader :ndx_error_list
     private
      def add_error(error,opts=Opts.new)
        # opts[:file_path] could be nil
        ndx = opts[:file_path]
        (@ndx_error_list[ndx] ||= Array.new) << error
        self
      end

      def add_errors(errors)
        errors.ndx_error_list.each_pair do |file_path,errors|
          ndx = file_path
          opts = (file_path ? Opts.new(:file_path => file_path) : Opts.new)
          errors.each{|error|add_error(error,opts)}
        end
      end 

      def error_prefix(num_errs)
        error_or_errors = (num_errs > 1 ? 'errors' : 'error')
        if @config_agent_type == :puppet
          "Puppet manifest parse #{error_or_errors}"
        else
          "Parse #{error_or_errors}"
        end
      end
    end
  end
end
