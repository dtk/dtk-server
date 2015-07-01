module DTK; class ActionDef; class Content
  class TemplateProcessor
    class MustacheTemplate < self
      include MustacheTemplateMixin

      def bind_template_attributes(command_line, attr_val_pairs)
        begin
          bind_template_attributes_utility(command_line,attr_val_pairs)
         rescue MustacheTemplateError::MissingVar => e
          ident = 4
          err_msg = "The mustache variable '#{e.missing_var}' in the following command is not set:\n#{' '*ident}#{command_line}"      
          raise ErrorUsage.new(err_msg)
         rescue MustacheTemplateError => e
          raise ErrorUsage.new("Template error in command (#{command_line}): #{e.error_message}")
        end
      end
    end
  end
end; end; end
