module DTKModule
  class Aws::Vpc
    class InternetGateway
      class Operation <  OperationBase
        OPERATIONS = [:get]
        OPERATIONS.each { |operation_name| require_relative("operation/#{operation_name}") }
        
        private

        def self.resource_class
          InternetGateway
        end

      end
    end
  end
end
