require 'mustache'

module DTK; class ActionDef; class Content
  class TemplateProcessor
    # For Rich: needed to change class name from Mustache to MustacheTemplate because Mustache class name is reserved by mustache gem
    class MustacheTemplate < self
      def needs_template_substitution?(command_line)
        # will return true if command_line has mustache template attributes '{{ variable }}'
        return command_line.match(/\{\{.+\}\}/)
      end

      def bind_template_attributes(command_line, attr_val_pairs)
        # using Mustache gem to extract attribute values; raise error if unbound attributes
        Mustache.raise_on_context_miss = true
        Mustache.render(command_line, attr_val_pairs)
      end
    end
  end
end; end; end
