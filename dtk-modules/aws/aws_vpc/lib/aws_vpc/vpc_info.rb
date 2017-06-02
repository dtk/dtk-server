module DTKModule
  class Aws::Vpc
    class VpcInfo < ::Hash
      def initialize(hash)
        super()
        replace(hash)
      end
      private :initialize

      def self.get_from_ec2_instance_meta_data?
        new(Ec2Metadata.get_vpc_info) if Ec2Metadata.is_on_an_ec2_instance?
      end

      class Ec2Metadata
        ATTRIBUTES = %w{vpc-id subnet-id subnet-ipv4-cidr-block security-group-ids security-groups}

        def self.is_on_an_ec2_instance?
          load_rest_client
          return @on_an_ec2_instance unless  @on_an_ec2_instance.nil?
          @on_an_ec2_instance = 
            if mac = get_mac?
              @mac = mac.sub('/', '')
              true
            else
              false
            end
        end

        def self.get_vpc_info
          fail "Unexpected that @mac is nil" if @mac.nil?
          ATTRIBUTES.inject({}) { |h, a| h.merge(a => get_attribute(a)) }
        end
        
        private
        
        INTERFACE_METADATA_URL = 'http://169.254.169.254/latest/meta-data/network/interfaces/macs'
        
        def self.get_mac?
          begin
            # TODO: update in case node has multiple NICs
            rest_get(INTERFACE_METADATA_URL)
          rescue
            # To catch case where not on ec2 instance
            nil
          end
        end
        
        def self.get_attribute(name)
          rest_get("#{INTERFACE_METADATA_URL}/#{@mac}/#{name}")
        end

        def self.rest_get(url)
          response = ::RestClient.get(url)
          fail "Bad rest error code '#{response.code}'" unless response.code == 200
          # String.new needed because of the issue in rest-client: no _dump_data is defined for class OpenSSL::X509::Store          
          String.new(response)
        end

        def self.load_rest_client
          unless @rest_client_loaded
            require 'rest_client'
            @rest_client_loaded = true
          end
        end
        
      end
    end
  end
end
