module DTK; class ModuleDSL; class V4
  class ObjectModelForm
    class ActionDef < self
      module Constant
        module Default
        end

        ActionDefs = ['actions','action']
        Default::ActionDefs = 'actions'

        Commands = ['commands','command']
        Default::Commands = 'commands'

        Provider = ['provider']
        Default::Provider ='provider'
      end

      def initialize(component_name)
        @component_name = component_name
        # TODO: right now hard coded
        @inherited_provider = ConfigAgent::Type::Symbol.dtk_provider
      end
      
      def convert_action_defs?(input_hash)
        ret = nil
        unless action_defs = matching_key?(Constant::ActionDefs,input_hash)
          return ret
        end
        unless action_defs.kind_of?(Hash)
          raise_error_ill_formed('actions section',action_defs)
        end
        action_defs.inject(OutputHash.new) do |h,(action_name,action_body)|
          h.merge(convert_action_def(action_name,action_body))
        end
      end

     private
      def convert_action_def(action_name,action_body)
        raise_error_if_illegal_action_name(action_name)
        action_body_hash = {
          :method_name  => action_name,
          :display_name => action_name,
          :content      => convert_action_body(action_body,:action_name => action_name)
        }
        {action_name => OutputHash.new(action_body_hash)}
      end

      def raise_error_if_illegal_action_name(action_name)
        unless action_name =~ LegalActionNameRegex
          err_msg = "The action name '?1' on component '?2' has illegal characters"
          raise ParsingError.new(err_msg,action_name,cmp_print_form())
        end
      end
      LegalActionNameRegex = /^[a-zA-Z0-9_-]+$/

      def convert_action_body(input_hash,context={})
        action_name = context[:action_name]
        unless input_hash.kind_of?(Hash)
          raise_error_ill_formed('action definition',{action_name => input_hash})
        end
        unless commands = matching_key?(Constant::Commands,input_hash)
          err_msg = "The following action definition for '?1' on component '?2' is missing the '?3' key: ?4"
          raise ParsingError.new(err_msg,action_name,cmp_print_form(),Constant::Default::Commands,input_hash)
        end
        hash = {
          :commands => commands.kind_of?(Array) ? commands : [commands],
          :provider => convert_action_provider(input_hash)
        }
        OutputHash.new(hash)
      end

      def convert_action_provider(input_hash)
         matching_key?(Constant::Provider,input_hash) || @inherited_provider.to_s
      end

      def raise_error_ill_formed(section_type,obj)
        err_msg = "The following #{section_type} on component '?1' is ill-formed: ?2"
        raise ParsingError.new(err_msg,cmp_print_form(),obj)
      end

      def cmp_print_form()
        component_print_form(@component_name)
      end

    end
  end
end; end; end
