module DTK; class ModuleDSL; class V4
  class ObjectModelForm
    class ActionDef < self
      r8_nested_require('action_def', 'provider')
      module Constant
        module Variations
        end
        extend Aux::ParsingingHelper::ClassMixin

        ActionDefs = 'actions'
        Variations::ActionDefs = ['actions', 'action']

        Provider = 'provider'
      end

      def initialize(component_name)
        @component_name = component_name
      end

      class ActionDefOutputHash < OutputHash
        def has_create_action?
          DTK::ActionDef::Constant.matches?(self, :CreateActionName)
        end

        def delete_create_action!
          if kv = DTK::ActionDef::Constant.matching_key_and_value?(self, :CreateActionName)
            delete(kv.keys.first)
          end
        end
      end

      def convert_action_defs?(input_hash)
        ret = nil
        unless action_defs = Constant.matches?(input_hash, :ActionDefs)
          return ret
        end
        unless action_defs.is_a?(Hash)
          raise_error_ill_formed('actions section', action_defs)
        end
        action_defs.inject(ActionDefOutputHash.new) do |h, (action_name, action_body)|
          h.merge(convert_action_def(action_name, action_body))
        end
      end

      private

      def convert_action_def(action_name, action_body)
        raise_error_if_illegal_action_name(action_name)
        action_body_hash = {
          method_name: action_name,
          display_name: action_name,
          content: Provider.create(action_body, action_name: action_name, cmp_print_form: cmp_print_form())
        }
        { action_name => OutputHash.new(action_body_hash) }
      end

      def raise_error_if_illegal_action_name(action_name)
        unless action_name =~ LegalActionNameRegex
          err_msg = "The action name '?1' on component '?2' has illegal characters"
          raise ParsingError.new(err_msg, action_name, cmp_print_form())
        end
      end
      LegalActionNameRegex = /^[a-zA-Z0-9_-]+$/

      def raise_error_ill_formed(section_type, obj)
        err_msg = "The following #{section_type} on component '?1' is ill-formed: ?2"
        raise ParsingError.new(err_msg, cmp_print_form(), obj)
      end

      def cmp_print_form
        component_print_form(@component_name)
      end
    end
  end
end; end; end
