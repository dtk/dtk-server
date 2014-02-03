module DTK; class Task
  class Template
    class ErrorParsing < ErrorUsage::DSLParsing
      def initialize(workflow_error_msg)
        err_msg = "Worklow parsing error: #{workflow_error_msg}"
        super(err_msg)
      end
    end
  end
end; end


