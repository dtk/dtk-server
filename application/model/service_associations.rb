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
  class ServiceAssociations < Model
    def self.create_associations(project, service_instance, parent_service_instance)
      display_name = "#{service_instance[:display_name]}-#{parent_service_instance[:display_name]}"

      row = {
        ref: display_name,
        display_name: display_name,
        relationship: 'parent-of',
        service_antecendent_id: service_instance[:id],
        service_dependent_id: parent_service_instance[:id]
      }

      association_mh = project.id_handle().createMH(:service_associations)
      Model.create_from_rows(association_mh, [row], convert: true)
    end

    def self.get_for_child(project, child_service_instance)
      sp_hash = {
        cols: [:dependent_parent_services],
        filter: [:eq, :service_antecendent_id, child_service_instance[:id]]
      }
      associations = Model.get_objs(project.id_handle().createMH(:service_associations), sp_hash)

      service_instances = []
      associations.each do |association|
        if service_instance = association[:service_instance]
          service_instances << service_instance.copy_as_assembly_instance
        end
      end

      service_instances
    end
  end
end
