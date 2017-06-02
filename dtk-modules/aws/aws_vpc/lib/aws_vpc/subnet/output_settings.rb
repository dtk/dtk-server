module DTKModule
  class Aws::Vpc
    class Subnet
      class OutputSettings <  OutputSettingsBase
        
        # Mapping from aws sdk call
        ATTRIBUTE_MAPPING = 
          [
           :subnet_id,
           :vpc_id,
           :availability_zone,
           { subnet_cidr_block: :cidr_block },
           { subnet_length: { fn: :map_subnet_length } }
          ]
        
        KEYS_TO_NIL_AFTER_DELETE = [:subnet_id, :availability_zone, :subnet_cidr_block]

        def self.map_subnet_length(aws_subnet_result)
          subnet_length_from_cidr_block(aws_subnet_result.cidr_block)
        end
        
        # Mapping from meta data call
        METADATA_ATTRIBUTE_MAPPING = {
          subnet_id: 'subnet-id',
          vpc_id: 'vpc-id',
          subnet_cidr_block: 'subnet-ipv4-cidr-block'
        }
        
        def self.map_from_ec2_metadata_vpc_info(vpc_info)
          ret = METADATA_ATTRIBUTE_MAPPING.inject(new) { |h, (dtk_attr, vpc_info_attr)| h.merge(dtk_attr => vpc_info[vpc_info_attr]) } 
          # One special processing rule
          ret.merge!(subnet_length: subnet_length_from_cidr_block(vpc_info['subnet-ipv4-cidr-block']))
          ret
        end

        def self.nil_values_after_delete
          KEYS_TO_NIL_AFTER_DELETE.inject(new) { |h, key| h.merge(key => nil) }
        end
 
        private
        
        def self.subnet_length_from_cidr_block(cidr_block)
          cidr_block.split('/').last
        end
        
      end
    end
  end
end

