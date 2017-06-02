module DTKModule
  module DTK
    class Error < ::Exception
      attr_reader :hash_form
      # opts can have keys
      #  error_code - integer
      #  error_message
      #  backtrace
      def initialize(opts = {})
        error_message = opts[:error_message] || Default::ERROR_MESSAGE
        add_backtrace!(error_message, opts[:backtrace]) if opts[:backtrace]
        error_code = opts[:error_code] || Default::ERROR_CODE
        @hash_form = ResponseOrErrorHashContent.new(:notok, Key.error_message => error_message, Key.error_code => error_code)
      end      

      module Default
        ERROR_CODE = 1
        ERROR_MESSAGE = 'unknown error'
      end

      class Usage < self
        # opts can have keys
        #  error_code - integer
        def initialize(error_message, opts = {})
          super(opts.merge(error_message: error_message))
        end
      end

      class Internal < self
        def initialize(exception)
          error_message = (exception.respond_to?(:message) ? exception.message : '')
          super(error_message: error_message, backtrace: exception.backtrace)
        end
      end

      private
      
      ERROR_BACKTRACE_INDENT = ' ' * 6
      def add_backtrace!(error_message, backtrace_array)
        backtrace = prune_backtrace_depth(backtrace_array).join("#{ERROR_BACKTRACE_INDENT}\n")
        error_message << "\n\n#{backtrace}"
      end

      DEFAULT_ERROR_BACKTRACE_DEPTH = 5
      STOP_POINT_REGEXP = /ruby-provider\/init/
      def prune_backtrace_depth(backtrace_array)
        depth = backtrace_array.find_index { |line| line =~ STOP_POINT_REGEXP } || DEFAULT_ERROR_BACKTRACE_DEPTH
        backtrace_array[0..depth]
      end      

      module Key
        def self.error_code
          @error_code_key ||= ResponseOrErrorHashContent::Key::ERROR_CODE
        end
        def self.error_message
          @error_message_key ||= ResponseOrErrorHashContent::Key::ERROR_MESSAGE
        end
      end

    end
  end
end

      
      
