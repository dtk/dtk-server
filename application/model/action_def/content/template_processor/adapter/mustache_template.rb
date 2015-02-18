require 'mustache'

module DTK; class ActionDef; class Content
  class TemplateProcessor
    class MustacheTemplate < self
      def needs_template_substitution?(command_line)
        # will return true if command_line has mustache template attributes '{{ variable }}'
        command_line.match(HasMustacheVarsRegExp)
      end
      HasMustacheVarsRegExp = /\{\{.+\}\}/

      def bind_template_attributes(command_line, attr_val_pairs)
        # using Mustache gem to extract attribute values; raise error if unbound attributes
        begin 
          ::Mustache.raise_on_context_miss = true
          ::Mustache.render(command_line, attr_val_pairs)
         rescue ::Mustache::ContextMiss => e
          raise ErrorUsage.new(e.message)
        end
      end
    end
  end
end; end; end
