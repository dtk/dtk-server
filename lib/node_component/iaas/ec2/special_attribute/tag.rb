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
module DTK
  class NodeComponent::IAAS
    class Ec2
      module Tag
        extend Mixin 

        def self.name(node_component)
          # TO-DO: move the tenant name definition to server configuration
          subs = {
            assembly: node_component.assembly_name,
            node: node_component.node_name,
            tenant: tenant,
            user: user,
            target: 'target' # TODO: hard coded
          }
          ret = Ec2NameTag[:tag].dup
          Ec2NameTag[:vars].each do |var|
            val = subs[var] || var.to_s.upcase
            ret.gsub!(Regexp.new("\\$\\{#{var}\\}"), val)
          end
          ret
        end
        
        Ec2NameTag = {
          vars: [:assembly, :node, :tenant, :target, :user],
          tag: R8::Config[:ec2][:name_tag][:format]
        }

      end
    end
  end
end
