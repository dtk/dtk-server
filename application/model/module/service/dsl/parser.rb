module DTK
  class ServiceModule
    class DSLParser < DTK::ModuleDSLParser
      def self.module_type()
        :service_module
      end
      def self.module_class
        ServiceModule
      end
    end
  end
end
