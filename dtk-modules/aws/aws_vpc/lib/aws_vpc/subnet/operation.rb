module DTKModule
  class Aws::Vpc
    class Subnet
      class Operation <  OperationBase
        OPERATIONS = [:get, :create, :delete]
        OPERATIONS.each { |operation_name| require_relative("operation/#{operation_name}") }
        
        #      include WaitConditions::Mixin
        #      extend WaitConditions::ClassMixin
        
        private
        
        def self.resource_class
          Subnet
        end

      end
    end
  end
end
