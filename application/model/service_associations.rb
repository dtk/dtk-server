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
  class ServiceAssociations < Model
    module Relation
      PARENT_OF = 'parent-of'
    end

    def self.create_associations(project, assembly_instance, parent_assembly_instance)
      display_name = "#{assembly_instance.display_name}-#{parent_assembly_instance.display_name}"

      row = {
        ref: display_name,
        display_name: display_name,
        relationship: Relation::PARENT_OF,
        service_antecendent_id: assembly_instance.id,
        service_dependent_id: parent_assembly_instance.id
      }

      association_mh = project.model_handle(:service_associations)
      create_from_rows(association_mh, [row], convert: true)
    end

    def self.get_parent?(assembly_instance)
      sp_hash = {
        cols: [:id, :group_id, :display_name, :service_dependent_id],
        filter: [:and,
                 [:eq, :service_antecendent_id, assembly_instance.id],
                 [:eq, :relationship, Relation::PARENT_OF]]
      }
      associations = get_objs(assembly_instance.model_handle(:service_associations), sp_hash)
      case associations.size
      when 0
        nil
      when 1
        assembly_instance.model_handle(:assembly_instance).createIDH(id: associations.first[:service_dependent_id]).create_object
      when 2
        fail ErrorUsage, "Not treating cases where  service instance has more than 1 parent"
      end
    end

  end
end
