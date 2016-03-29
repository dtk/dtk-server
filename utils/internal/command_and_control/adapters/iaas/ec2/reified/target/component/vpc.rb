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

        attr_reader :id

        DefaultRegion = 'us-east-1'
        def initialize(reified_target, vpc_service_component)
          super(reified_target, vpc_service_component)
          @id, @reqion, @aws_access_key_id, @aws_secret_access_key = get_attribute_values(:id, :reqion, :aws_access_key_id, :aws_secret_access_key)
          @region ||= DefaultRegion
          @id_validated = false
        end 

        # Returns an array of violations; if no violations [] is returned
        def validate_and_converge!
          if @id
            Log.info("vpc id = '#{@id}'")
            unless @id_validated
              # TODO: validate if @id is a valid vpc id
              # validate_vpc id(@id)
              # @id_validated = true
            end
          end
          []
        end

        def id=(vpc_id)
          @id_validated = true
          # TODO: need to update the refiend attribute cache of anything this propagates to
          Log.info("TODO: set and propagate the dtk id attribute '#{vpc_id}]")
          @id = vpc_id
        end

        def credentials_with_region 
          { 
            aws_access_key_id: @aws_access_key_id,
            aws_secret_access_key: @aws_secret_access_key,
            region: @region
          }
        end

        def aws_conn
          @conn ||= Ec2.conn(credentials_with_region)
        end
      end
    end
  end
end; end



