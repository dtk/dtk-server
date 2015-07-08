module DTK; class ModuleDSL; class V4; class ObjectModelForm
  class ActionDef
    class Provider < OutputHash
      r8_nested_require('provider','puppet')
      r8_nested_require('provider','dtk')

      def initialize(provider_type,input_hash)
        super(provider: provider_type.to_s).merge!(provider_specific_fields(input_hash))
      end
      def self.create(input_hash,context={})
        action_name = context[:action_name]
        cmp_print_form = context[:cmp_print_form]
        unless input_hash.is_a?(Hash)
          err_msg = "The following action definition on component '?1' is ill-formed: ?2"
          raise ParsingError.new(err_msg,cmp_print_form,action_name => input_hash)
        end
        provider_type = provider_type(input_hash,context)
        unless provider_class = ProviderTypeToClass[provider_type.to_sym]
          err_msg = "The action '?1' on component '?2' has illegal provider type: ?3"
          raise ParsingError.new(err_msg,action_name,cmp_print_form,provider_type)
        end
        provider_class.new(provider_type,input_hash)
      end

      private
      
      ProviderTypeToClass = {
        dtk: Dtk,
        puppet: Puppet 
      }

      # gets overwritten
      def provider_specific_fields(_input_hash)
        raise Error.new("should be overwritten")
      end

      def self.provider_type(input_hash,context={})
        Constant.matches?(input_hash,:Provider) || compute_provider_type(input_hash,context)
      end

      def self.compute_provider_type(input_hash,context={})
        ret = nil
        if provider_class = ProviderTypeToClass.find{|_provider,klass|klass.matches_input_hash?(input_hash)}
          ret = provider_class[0]
        end
        unless ret
          action_name = context[:action_name]
          cmp_print_form = context[:cmp_print_form]
          err_msg = "Cannot determine provider type associated with the action '?1' on component '?2'"
          raise ParsingError.new(err_msg,action_name,cmp_print_form)
        end
        ret
      end
    end
  end
end; end; end; end
