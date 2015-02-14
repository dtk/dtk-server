module DTK; class ActionDef; class Content
  class Command
    class Syscall < self
      attr_reader :string_form
      def initialize(raw_form,string_form)
        @raw_form = raw_form
        @string_form = string_form
      end

      def self.parse?(serialized_command)
        if serialized_command.kind_of?(String) and serialized_command =~ Constant::Command::RunRegexp
          string_form = $1
          new(serialized_command,string_form)
        end
      end

    end
  end
end; end; end              
