module DTK; class AttributeLink
  class Function
    class Eq < Base
      def internal_hash_form(opts = {})
        UpdateDelta.new(value_derived: output_value(opts))
      end
    end
  end
end; end
