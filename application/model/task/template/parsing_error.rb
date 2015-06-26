module DTK; class Task
  class Template
    class ParsingError < ErrorUsage::Parsing
      def initialize(msg,*args_x)
        args = Params.add_opts(args_x,:error_prefix => ErrorPrefix,:caller_info => true)
        super(msg,*args)
      end
      ErrorPrefix = 'Workflow parsing error'
    end

  end
end; end


