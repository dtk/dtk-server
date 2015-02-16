module DTK; class ActionDef; class Content
  class TemplateProcessor
    class Mustache < self
      def needs_template_substitution?(command_line)
        # For Aldin DTK-1911: DTK-1930
        # returns true if command_line has template variables
        nil # TODO: stub
      end

      def bind_template_attributes!(command_line,attr_val_pairs)
        # For Aldin DTK-1911: DTK-1930
        # TODO: stub
        # this substitutes attr_val_pairs into command_line
        # raises error if there are any unbound attributes in command_line or any arre non scalars (i.e., hashes or arrays)
      end
    end
  end
end; end; end
