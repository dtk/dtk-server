module DTK; class Attribute
  class LegalValue 
    def self.raise_usage_errors?(existing_attrs,ndx_new_vals)
      errors = ErrorsUsage.new
      existing_attrs.each do |a|
        new_val = ndx_new_vals[a[:id]]
        special_processing,error = SpecialProcessing::ValueCheck.error_special_processing?(a,new_val)
        if special_processing
          errors << error if error
        else
          # TODO: stub for normal error processing
        end
      end
      unless errors.empty?
        raise errors
      end
    end
    class Error < ErrorUsage 
      def initialize(attr,new_val,info={})
        super(error_msg(attr,new_val,info))
      end

      private

      def error_msg(attr,new_val,info)
        attr_name = attr[:display_name]
        ret = "Attribute (#{attr}) has illegal value (#{new_val})" 
        if legal_vals = info[:legal_values]
          ident = " "*2;
          sep = "--------------"
          ret << "; legal values are: \n#{sep}\n#{ident}#{legal_vals.join("\n#{ident}")}" 
          ret << "\n#{sep}\n"
        end
        ret
      end
    end
  end
end; end

