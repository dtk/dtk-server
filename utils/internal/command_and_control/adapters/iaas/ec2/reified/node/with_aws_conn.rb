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
require 'fog/aws'

module DTK; module CommandAndControlAdapter
  class Ec2
    class Reified::Node
      class WithAwsConn < self
        r8_nested_require('with_aws_conn', 'image')

        # opts will have keys
        #  :reified_target
        #  :dtk_node_or_node_group
        def initialize(opts)
          @reified_target = opts[:reified_target]
          super(opts)

          # The attributes below get dynamically set
          @aws_conn = nil
          @image    = nil
        end
        private :initialize

        def image
          @image ||= Image.validate_and_create_object(ami, self)
        end

        def aws_conn
          @aws_conn ||= get_aws_conn
        end

        def connected_component(conn_cmp_type)
          connected_component_aux(conn_cmp_type, @reified_target)
        end

        private

        def vpc_component
          connected_component(:vpc_subnet).connected_component(:vpc)
        end

        def get_vpc_component
          ret_singleton_or_raise_error('vpc', @reified_target.vpc_components)
        end

        def credentials_with_region
          vpc_component.credentials_with_region
        end

        def get_aws_conn
          Ec2.conn(credentials_with_region)
        end
      end
    end
  end
end; end
