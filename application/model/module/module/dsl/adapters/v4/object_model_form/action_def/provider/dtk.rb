module DTK; class ModuleDSL; class V4; class ObjectModelForm
  class ActionDef; class Provider 
    class Dtk  < self
      module Constant
        module Variations
        end
        extend Aux::ParsingingHelper::ClassMixin

        Commands = 'commands'        
        Variations::Commands = ['commands','command']
      end

      def self.matches_input_hash?(input_hash)
        !!Constant.matches?(input_hash,:Commands)
      end

      def provider_specific_fields(input_hash)
        commands   = Constant.matches?(input_hash,:Commands)
        ret        = {:commands => commands.kind_of?(Array) ? commands : [commands]}
        stdout_err = input_hash['stdout_and_stderr']

        unless stdout_err.nil?
          raise ParsingError.new(":stdout_and_stderr has invalid value. Must be set to true or false") unless ['true','false'].include?(stdout_err.to_s)
          ret.merge!(:stdout_and_stderr => stdout_err)
        end

        ret
      end
    end
  end; end
end; end; end; end
