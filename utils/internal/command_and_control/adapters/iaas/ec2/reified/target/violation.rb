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

module DTK; class CommandAndControlAdapter::Ec2
  module Reified
    class Target
      class Violation < Reified::Violation
        
        class InvalidCredentials < self
          # TODO: parameterize by component title when have multiple credentials in target
          def initialize
          end
          def description
            "One or both of the AWS credentials 'aws_access_key_id'/'aws_secret_access_key' are invalid"
          end
        end

        class InvalidVpcSubnetId < self
          # opts can have keys
          #  :legal_subnet_ids
          def initialize(vpc_subnet_id, opts = {})
            @vpc_subnet_id = vpc_subnet_id
            @legal_subnet_ids = opts[:legal_subnet_ids]
          end
          def description
            ret = "The id '#{@vpc_subnet_id}' is an invalid vpc subnet id"
            ret << "; legal values are: #{@legal_subnet_ids.join(', ')}" if @legal_subnet_ids
            ret
          end
        end
        
        class InvalidKeypair < self
          def initialize(keypair, region, legal_keypairs)
            @keypair        = keypair
            @region         = region
            @legal_keypairs = legal_keypairs
          end
          def description
            if @legal_keypairs.empty?
              "There are no keypairs configured in region '#{@region}'"
            else
              "The name '#{@keypair}' is not a legal keypair in region '#{@region}'; legal values are: #{@legal_keypairs.join(', ')}" 
            end
          end
        end
        
        class InvalidSecurityGroup < self
          class Id < self
            def initialize(id, vpc_id, legal_ids)
              super(:id, id, vpc_id, legal_ids)
            end
          end
          
          class Name < self
            def initialize(name, vpc_id, legal_names)
              super(:name, name, vpc_id, legal_names)
            end
          end

          def initialize(type, name_or_id, vpc_id, legal_items)
            @type        = type
            @name_or_id  =  name_or_id
            @vpc_id      = vpc_id
            @legal_items = legal_items
          end
          private :initialize

          def description
            if @legal_items.empty?
              "There are no #{type_ref}s configured in vpc '#{@vpc_id}'"
            else
              "The name '#{@name_or_id}' is not a legal #{type_ref} in vpc '#{@vpc_id}'; legal values are: #{@legal_items.join(', ')}" 
            end
          end
          def type
            "invalid_security_group_#{@type}".to_sym
          end
          
          private
          
          def type_ref
            "security group #{@type}"
          end
        end
        
      end
    end
  end
end; end

