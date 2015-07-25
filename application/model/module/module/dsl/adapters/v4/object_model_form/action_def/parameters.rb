module DTK; class ModuleDSL::V4::ObjectModelForm
  class ActionDef
    class Parameters
      def self.create?(input_hash, context = {})
        ret = nil
        unless parameters = Constant.matches?(input_hash, :Parameters)
          return ret
        end
        pp [:debug,parameters]
        nil
      end
    end
  end
end; end
