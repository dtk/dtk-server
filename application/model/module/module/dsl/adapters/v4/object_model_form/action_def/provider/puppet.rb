module DTK; class ModuleDSL; class V4; class ObjectModelForm
  class ActionDef; class Provider 
    class Puppet < self 
      module Constant
        module Variations
        end
        extend Aux::ParsingingHelper::ClassMixin

        PuppetClass = 'puppet_class'
        PuppetDefinition = 'puppet_definition'
      end
      AllKeys = [:PuppetClass,:PuppetDefinition]

      def self.matches_input_hash?(input_hash)
        !!AllKeys.find{|k|Constant.matches?(input_hash,k)}
      end
      
      def provider_specific_fields(input_hash=nil)
        input_hash ||= self
        AllKeys.inject({}) do |h,k|
          h.merge(Constant.matching_key_and_value?(input_hash,k)||{})
        end
      end

      def external_ref_from_create_action
        provider_specific_fields()
      end
    end
  end; end
end; end; end; end
