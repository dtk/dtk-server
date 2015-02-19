require 'mustache'

module DTK; class ActionDef; class Content
  class TemplateProcessor
    class MustacheTemplate < self
      def needs_template_substitution?(command_line)
        # will return true if command_line has mustache template attributes '{{ variable }}'
        command_line =~ HasMustacheVarsRegExp
      end
      HasMustacheVarsRegExp = /\{\{.+\}\}/

      def bind_template_attributes(command_line, attr_val_pairs)
        # using Mustache gem to extract attribute values; raise error if unbound attributes
        begin 
          ::Mustache.raise_on_context_miss = true
          ::Mustache.render(command_line, attr_val_pairs)
         rescue ::Mustache::ContextMiss => e
          raise ErrorUsage.new(normalize_mustache_context_miss_error(e,command_line))
        end
      end

      def normalize_mustache_context_miss_error(mustache_gem_err,command_line)
        str_err = mustache_gem_err.message
        if str_err =~ /^Can't find ([^\s]+) in/
          missing_var = $1
          ident = 4
          "The mustache variable '#{missing_var}' in the following command is not set:\n#{' '*ident}#{command_line}"
        else
          "Template error in command (#{command_line}): #{str_err}"
        end
      end
    end
  end
end; end; end
