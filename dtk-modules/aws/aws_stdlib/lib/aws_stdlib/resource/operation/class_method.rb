module DTKModule
  class Aws::Stdlib::Resource
    class Operation
      class ClassMethod
        def initialize(object_called_from, resource_class)
          @client         = object_called_from.client
          @resource_class = resource_class 
        end
        
        attr_reader :client
        
        private

        attr_reader :resource_class
        
        def output_settings_array(aws_result_object_array)
          aws_result_object_array.map { |aws_result_object| resource_class::Operation.output_settings(aws_result_object) }
        end
      end
    end
  end
end

