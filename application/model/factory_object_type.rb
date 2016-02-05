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
  module FactoryObject
    CommonCols = COMMON_REL_COLUMNS.keys - [:local_id, :c, :created_at, :updated_at]
  end
  module FactoryObjectCommon
    def assembly_template_node_ref(assembly_ref, node_ref)
      "#{assembly_ref}--#{node_ref}"
    end
  end

  module FactoryObjectMixin
    include FactoryObjectCommon
    def qualified_ref(obj_hash)
      "#{obj_hash[:ref]}#{obj_hash[:ref_num] ? "-#{obj_hash[:ref_num]}" : ''}"
    end

    def id_handle_if_object_exists?
      ret = id_handle()
      ret if ret.get_id()
    end
  end
  module FactoryObjectClassMixin
    include FactoryObjectCommon

    def create(model_handle, hash_values)
      idh = (hash_values[:id] ? model_handle.createIDH(id: hash_values[:id]) : model_handle.create_stubIDH())
      new(hash_values, model_handle[:c], model_name(), idh)
    end

    def subclass_model(model_object)
      new(model_object, model_object.model_handle[:c], model_name(), model_object.id_handle())
    end
  end
end