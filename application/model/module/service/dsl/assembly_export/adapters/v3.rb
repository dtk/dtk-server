module DTK
  class ServiceModule; class AssemblyExport
    r8_require('v2')
    class V3 < V2
     private
      def dsl_version()
        nil
      end
    end
  end; end
end
