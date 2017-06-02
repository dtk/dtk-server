module DTKModule
  class Aws::Vpc
    class Subnet::Operation
      class Delete < self
        class InputSettings < DTK::Settings
          REQUIRED = [:subnet_id]
        end

        def delete_subnet
          client.delete_subnet(subnet_id: params.subnet_id)
        end

      end
    end
  end
end
