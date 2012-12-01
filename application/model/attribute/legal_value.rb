module DTK; class Attribute
  class LegalValue
    def self.raise_usage_errors?(attr_mh,attribute_rows)
      #TODO: stub
      pp attribute_rows
      errors = Array.new
      attribute_rows.each do |av_pair|
        special_processing,error = SpecialProcessing::ValueCheck.error_special_processing?(attr_mh,av_pair)
        if special_processing
          if error
            errors << error 
          end
        else
          #TODO: stub for normal error processing
        end
      end
    end
    class Errors < ErrorUsage
      def initialize(errors)
        super(errors_to_msg(errors))
      end
      private
      def errors_to_msg(errors)
        errors.map{|err|err.to_s}.join("\n")
      end
    end
    class Error 
    end
  end
end; end

