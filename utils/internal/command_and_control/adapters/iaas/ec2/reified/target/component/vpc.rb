#
# Copyright (C) 2010-2016 dtk contributors
#
# This file is part of the dtk project.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module DTK; module CommandAndControlAdapter
  class Ec2::Reified::Target
    class Component
      class Vpc < self
        Attributes = [:id, :region, :aws_access_key_id, :aws_secret_access_key, :default_keypair, :cidr_block]

        DefaultRegion = 'us-east-1'
        def initialize(reified_target, vpc_service_component)
          super(reified_target, vpc_service_component)
          @id = nil # for when id gets propagated from vpc_subnet
        end 

        def region
          super || DefaultRegion
        end

        # Returns an array of violations; if no violations [] is returned
        def validate_and_converge!
          ret = []
          if id
            unless @id
              # TODO: validate if @id is a valid vpc id
              # validate_vpc id(@id)
              # @id = ..
            end
          end
          ret += validate_default_keypair
          
          set_attributes_from_aws! if ret.empty?
          
          ret
        end

        #once @id is set dont want clear_all_attribute_caches! to change it
        def id
          @id || super
        end
        def id=(vpc_id)
          @id = update_and_propagate_dtk_attribute(:id, vpc_id) 
          # clear_all_attribute_caches! is needed to avoid having component dependending on vpc_id having
          # cached value
          clear_all_attribute_caches!
          @id
        end

        def credentials_with_region
          { 
            aws_access_key_id: aws_access_key_id,
            aws_secret_access_key: aws_secret_access_key,
            region: region
          }
        end

        def aws_conn
          # TODO: make sure this does not get set if bad credentilas
          #       Right now raises a lower level error -> server error about aws credentials
          #       want to handle by treating error and putting in a violation about bad credentails
          @conn ||= Ec2.conn(credentials_with_region)
        end
        
        private

        def set_attributes_from_aws!
          unless cidr_block
            unless id
              Log.error("Unexpected that id is not set")
              return
            end
            unless aws_vpc = aws_conn.vpc?(id)
              Log.error("Unexpected that cannot find aws_vpc")
              return
            end
            name_value_pairs = Aux.hash_subset(aws_vpc, [:cidr_block])
            update_and_propagate_dtk_attributes(name_value_pairs, prune_nil_values: true)
          end
        end
        
        def validate_default_keypair
          ret = []
          unless default_keypair = default_keypair()
            Log.error("Unexpected that default_keypair is not set")
            return ret
          end
          
          unless aws_conn.keypair?(default_keypair)
            keypair_names = aws_conn.keypairs.map { |keypair| keypair[:name] }
            ret += [Violation::InvalidKeypair.new(default_keypair, region, keypair_names)]
          end
          ret
        end
      end
    end
  end
end; end



