module DTK
  class ServiceSetting
    class Array < ::Array
      def initialize(assembly)
        @assembly = assembly
      end
      # returns a ServiceSetting by successively apply the ServiceSettings in the array
      # or returns nil if no service setting
      def collapse(opts={})
        if empty?
          nil
        elsif size == 1
          first.reify!(@assembly,opts)
        else
          raise Error.new("need to write")
        end
      end
    end
  end
end

