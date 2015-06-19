module DTK; class ActionDef; class Content
  class Command
    class FilePositioning < self
      attr_reader :command_line

      def initialize(serialized_command)
        @raw_form = serialized_command
        @command_line = serialized_command
        @template_processor = Content::TemplateProcessor.default() # TODO: changed when have multiple choices for template processors
        @needs_template_substitution = !!@template_processor.needs_template_substitution?(serialized_command[:target]) || !!@template_processor.needs_template_substitution?(serialized_command[:source])
        @is_template = serialized_command[:template]
        @is_executable = serialized_command[:executable]
      end

      def needs_template_substitution?
        @needs_template_substitution
      end

      def template?
        @is_template
      end

      def executable?
        @is_executable
      end

      def self.parse?(serialized_command)
        if serialized_command.is_a?(Hash) && serialized_command.key?(:ADD)
          new(serialized_command)
        end
      end

      def bind_template_attributes!(attr_val_pairs)
        attr_val_pairs.merge!(:version => '9.4')
        if target = @command_line[:target]
          @command_line[:target] = @template_processor.bind_template_attributes(target, attr_val_pairs)
        end

        if source = @command_line[:source]
          @command_line[:source] = @template_processor.bind_template_attributes(source, attr_val_pairs)
        end

        # @command_line = @template_processor.bind_template_attributes(@command_line, attr_val_pairs)
        @needs_template_substitution = false
        self
      end

      def type
        'file'
      end
    end
  end
end; end; end              
