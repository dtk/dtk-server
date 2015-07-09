module DTK; class ModuleDSL; class V4; class ObjectModelForm
  class ActionDef; class Provider
    class Dtk < self
      module Constant
        module Variations
        end
        extend Aux::ParsingingHelper::ClassMixin

        Commands = 'commands'
        Variations::Commands = ['commands', 'command']

        Functions = 'functions'
        Variations::Functions = ['functions', 'function']
      end

      def self.matches_input_hash?(input_hash)
        !!Constant.matches?(input_hash, :Commands) || !!Constant.matches?(input_hash, :Functions)
      end

      def provider_specific_fields(input_hash)
        ret =
          if commands = Constant.matches?(input_hash, :Commands)
            { commands: commands.is_a?(Array) ? commands : [commands] }
          elsif functions = Constant.matches?(input_hash, :Functions)
            { functions: functions.is_a?(Array) ? functions : [functions] }
          end

        stdout_err = input_hash['stdout_and_stderr']
        unless stdout_err.nil?
          fail ParsingError.new(':stdout_and_stderr has invalid value. Must be set to true or false') unless ['true', 'false'].include?(stdout_err.to_s)
          ret.merge!(stdout_and_stderr: stdout_err)
        end

        ret
      end

      def external_ref_from_function
        if functions = self[:functions]
          type = functions.first.slice('type')
        end
      end

      def external_ref_from_bash_command
        { type: 'bash_command' }
      end
    end
  end; end
end; end; end; end
