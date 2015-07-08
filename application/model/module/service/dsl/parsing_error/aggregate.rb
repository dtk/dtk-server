module DTK; class ServiceModule
  class ParsingError
    class Aggregate
      def initialize(opts={})
        @aggregate_error = nil
        @error_cleanup = opts[:error_cleanup]
      end

      def aggregate_errors!(ret_when_err=nil,&_block)
        begin
          yield
         rescue DanglingComponentRefs => e
          @aggregate_error = e.add_with(@aggregate_error)
          ret_when_err
         rescue AmbiguousModuleRef => e
          @aggregate_error = e.add_with(@aggregate_error)
          ret_when_err
         rescue Exception => e
          @error_cleanup.call() if @error_cleanup
          raise e
        end
      end

      def raise_error?(opts={})
        if @aggregate_error
          @error_cleanup.call() if @error_cleanup
          error = @aggregate_error.add_error_opts(Opts.new(log_error: false))
          opts[:do_not_raise] ? error : raise(error)
        end
      end
    end
  end
end; end
