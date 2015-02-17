module DTK; class ActionDef; class Content
  class Command
    class Syscall < self
      r8_nested_require('syscall','interpret_results')

      attr_reader :command_line
      def needs_template_substitution?()
        @needs_template_substitution
      end
      def initialize(raw_form,command_line)
        @raw_form = raw_form
        @command_line = command_line
        @template_processor = Content::TemplateProcessor.default() # TODO: changed when have multiple choices for template processors
        @needs_template_substitution = !!@template_processor.needs_template_substitution?(command_line) 
      end

      def self.parse?(serialized_command)
        if serialized_command.kind_of?(String) and serialized_command =~ Constant::Command::RunRegexp
          command_line = $1
          new(serialized_command,command_line)
        end
      end

      def bind_template_attributes!(attr_val_pairs)
        @command_line = @template_processor.bind_template_attributes(@command_line, attr_val_pairs)
        @needs_template_substitution = false
        self
      end
    end
  end
end; end; end              
