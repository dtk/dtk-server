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
  class Region < Model
    set_relation_name(:region, :region)
    class << self
      def up
        column :ds_attributes, :json
        column :is_deployed, :boolean, default: false
        column :type, :varchar, size: 25 #type is availability_zone, datacenter, vdc
        one_to_many :region
        many_to_one :library
      end
    end
  end
  # TBD: do not include association between region gateway and network region of node since this is inferede through theer connection to a network partition; this also allows for more advanced models where node or gateway spans two differnt regions
  class AssocRegionNetwork < Model
    set_relation_name(:region, :assoc_network_partition)
    class << self
      def up
        foreign_key :network_partition_id, :network_partition, FK_CASCADE_OPT
        foreign_key :region_id, :region, FK_CASCADE_OPT
        many_to_one :library
      end
    end
  end
end