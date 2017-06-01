module DTKModule
  class Aws::Stdlib::Resource
    class Ec2
      class Keypair
        def initialize(credentials_handle)
          @client = Ec2.client(credentials_handle)
        end

        def self.import(credentials_handle, key_name, ssh_public_key)
          new(credentials_handle).import(key_name, ssh_public_key)
        end
        def import(key_name, ssh_public_key)
          unless exists?(key_name)
            params = {
              key_name: key_name,
              public_key_material: ssh_public_key
            }
            client.import_key_pair(params)
          end
          {}
        end
 
        private

        attr_reader :client

        def exists?(key_name)
          found_key_pairs = []
          begin
            found_key_pairs = client.describe_key_pairs(key_names: [key_name]).key_pairs
          rescue ::Aws::EC2::Errors::InvalidKeyPairNotFound
            # This traps error that occurs if key_name is not a key pair
          end
          found_key_pairs.find { |key_pair| key_pair.key_name == key_name}
        end
        
      end
    end
  end
end
