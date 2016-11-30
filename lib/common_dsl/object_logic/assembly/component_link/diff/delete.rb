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
module DTK; module CommonDSL 
  class ObjectLogic::Assembly
    class ComponentLink::Diff
      class Delete < CommonDSL::Diff::Element::Delete
        def process(result, opts = {})
          assembly_instance   = service_instance.assembly_instance
          port_links          = assembly_instance.get_augmented_port_links
          matching_port_links = port_links.select{ |port_link| port_link[:display_name].eql?(relative_distinguished_name) }
          matching_link       = nil

          if matching_port_links.size > 1
            result.add_error_msg("Unexpected that component link '#{relative_distinguished_name}' match multiple links")
          else
            matching_link = matching_port_links.first
          end

          DTK::Assembly::Instance::ServiceLink.delete(matching_link.id_handle)
          result.add_item_to_update(:assembly)
        end

      end
    end
  end
end; end
