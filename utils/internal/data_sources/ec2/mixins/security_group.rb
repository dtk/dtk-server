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
module XYZ
  module DSConnector
    module Ec2SecurityGroupInstanceMixin
      def get_network_partitions
        @network_partition_cache[:network_partions] ||= Local.new(self).get_network_partitions()
      end

      def get_network_partition_ref(server)
        return nil unless server[:groups] and not server[:groups].empty?
        server[:groups].sort.join('__')
      end

      def security_groups_from_network_partition_ref(ref)
        ref.split('__')
      end

      # internal fns for mixin
      class Local
        def initialize(parent)
          @parent = parent
        end

        def get_network_partitions
          network_partition_names = get_network_partition_refs()

          ret = DataSourceUpdateHash.new
          network_partition_names.each do |name|
            network_partition = { name: name } #TODO: stub for putting more information in
            ret[name] = network_partition
          end
          ret
        end

        private

        def get_network_partition_refs
          @parent.get_servers().map { |s| s[:network_partition_ref] }.compact.uniq
        end

        def conn
          @parent.conn()
        end

        # determines whether security group allows unfettered connectivity between its members
        # TODO: factor this in
        def get_unfettered_security_groups
          security_groups = conn().security_groups_all()
          security_groups.reject { |sg| not is_unfettered_security_group?(sg) }
        end

        def is_unfettered_security_group?(security_group)
          rules =  security_group[:ip_permissions]
          return nil unless rules
          true #TODO: stub
          # TODO: need to replace; this is rule for right_aws, not fog rules.find{|x|x.has_key?(:group) and x[:group] == sg_name} ? true : nil
        end
      end
    end
  end
end