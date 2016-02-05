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
  module DSNormalizer
    class Ec2
      module MonitoringItemsClassMixin
        def default_node_monitoring_items
          DefaultChecks.inject(DBUpdateHash.new) { |h, o| h.merge(o[:display_name] => o) }
        end
        DefaultChecks =
          [
           { description: 'ping',
             display_name: 'check_ping',
             enabled: true
          },

           { description: 'Free Space All Disks',
             display_name: 'check_all_disks',
             enabled: true
          },
           { description: 'Free Memory',
             display_name: 'check_mem',
             enabled: true
          },

           { description: 'Iostat',
             display_name: 'check_iostat',
             enabled: true
          },
           { description: 'Memory Profiler',
             display_name: 'check_memory_profiler',
             enabled: true
         },
           { description: 'SSH',
             display_name: 'check_ssh',
             enabled: true
          },
           { description: 'Processes',
             display_name: 'check_local_procs',
             enabled: true
          }
          ]
      end
    end
  end
end