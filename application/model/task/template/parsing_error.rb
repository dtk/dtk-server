module DTK; class Task
  class Template
    class ParsingError < ErrorUsage::Parsing
      def initialize(error_msg,*args)
        workflow_error_msg = "Worklow parsing error: #{error_msg}"
        super(workflow_error_msg,*args)
      end
    end
  end
end; end


