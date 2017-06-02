module DTKModule
  require_relative('../../aws_stdlib/lib/aws_stdlib') # TODO: replace with a 'dtk_module_require' method supplied by ruby provider
  module Aws
    class Vpc < Aws::Stdlib::Resource
      OperationBase     = Aws::Stdlib::Resource::Operation
      OutputSettingsBase = Aws::Stdlib::Resource::OutputSettings

      require_relative('aws_vpc/vpc_info')
      require_relative('aws_vpc/filter')
      
      # Classes below are Vpc resources
      require_relative('aws_vpc/subnet')
      require_relative('aws_vpc/internet_gateway')

      private

      def aws_client_class
        ::Aws::EC2::Client
      end

    end
  end
end
