module DTKModule
  class Aws::Vpc
    class InternetGateway::Operation
      class Get < self
        class ClassMethod < OperationBase::ClassMethod
          # Returns an array of InternetGateway::OutputSettings
          def describe_internet_gateways(vpc_id)
            filter = Filter.new('attachment.vpc-id', vpc_id)
            aws_internet_gateway_result = client.describe_internet_gateways(filters: [filter.hash]).internet_gateways
            output_settings_array(aws_internet_gateway_result)
          end

        end
      end
    end
  end
end
