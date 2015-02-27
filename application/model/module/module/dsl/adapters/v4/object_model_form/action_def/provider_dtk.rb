module DTK; class ModuleDSL; class V4; class ObjectModelForm
  class ActionDef 
    class ProviderDtk 
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

      def self.provider_specific_fields(input_hash)
        commands = Constant.matches?(input_hash,:Commands)
        {:commands => commands.kind_of?(Array) ? commands : [commands]}
      end
    end
  end
end; end; end; end
