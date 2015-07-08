module DTK; class Attribute::Pattern
  class Assembly; class Link
    class Target < self
      def self.create_attr_pattern(base_object,target_attr_term)
        attr_pattern = super(base_object,strip_special_symbols(target_attr_term))
        new(attr_pattern,target_attr_term)
      end

      attr_reader :attribute_pattern
      def attribute_idhs
        @attribute_pattern.attribute_idhs()
      end

      def component_instance
        @attribute_pattern.component_instance()
      end

      def is_antecedent?
        @is_antecedent
      end

      private

      def initialize(attr_pattern,target_attr_term)
        @attribute_pattern = attr_pattern
        @is_antecedent = compute_if_antecedent?(target_attr_term)
      end

      def compute_if_antecedent?(target_attr_term)
        !!(target_attr_term =~ /^\*/)
      end
      def self.strip_special_symbols(target_attr_term)
        target_attr_term.gsub(/^\*/,'')
      end
    end
  end; end
end; end
