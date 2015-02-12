module DTK; class ModuleDSL; class V4
  class ObjectModelForm
    class ActionDef < self
      module Constant
        ActionDefs = ['action','actions']
      end

      def initialize(component)
        @component = component
      end
      
      def convert_action_defs?(input_hash)
        ret = nil
        unless action_defs = matching_key?(Constant::ActionDefs,input_hash)
          return ret
        end
        pp [:debug,@component,@component.class]
        pp [:debug,action_defs,action_defs.class]
        unless action_defs.kind_of?(Hash)
          raise_error_ill_formed('actions',action_defs)
        end

#        ret = OutputHash.new
        ret
      end
      private
      def raise_error_ill_formed(section_type,obj)
        err_msg = "The following #{section_type} section on component '?1' is ill-formed: ?2"
        raise ParsingError.new(err_msg,component_print_form(@component),obj)
      end
    end
  end
end; end; end
