module DTKModule
  class Aws::Stdlib::Resource
    class Ec2 < self
      require_relative('ec2/key_pair')
      def self.client(credentials_handle)
        ::Aws::EC2::Client.new(client_opts(credentials_handle))
      end
    end

  end
end
