module DTK; class ModuleDSL; class V4
  class ObjectModelForm 
    class Component < OMFBase::Component
     private
      def body(input_hash,cmp,context={})
        ret = super
        ret.set_if_not_nil("action_def",ActionDef.new(cmp).convert_action_defs?(input_hash))
        ret
      end
    end
  end
end; end; end
