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
  module ModelDataClassMixins
    def get_factory_id_handle(parent_id_handle, relation_type = nil)
      IDInfoTable.get_factory_id_handle(parent_id_handle, relation_type || @relation_type)
    end

    def get_child_id_handle_from_qualified_ref(factory_id_handle, qualified_ref)
      unless factory_uri = factory_id_handle[:uri]
        factory_id_info = IDInfoTable.get_row_from_id_handle(factory_id_handle)
        return nil if factory_id_info.nil?
        factory_uri = factory_id_info[:uri]
      end

      child_uri = RestURI.ret_child_uri_from_qualified_ref(factory_uri, qualified_ref)
      IDHandle[c: factory_id_handle[:c], uri: child_uri]
    end

    # TODO: encapsulate with other fns that make assumption about guid to id relationship
    def get_row_from_id_handle(id_handle, opts = {})
      IDInfoTable.get_row_from_id_handle(id_handle, opts)
    end

    def get_child_id_handle(factory_id_handle, child_qualified_ref)
      c = factory_id_handle[:c]
      child_uri = RestURI.ret_child_uri_from_qualified_ref(factory_id_handle[:uri], child_qualified_ref)
      IDHandle[c: c, uri: child_uri]
    end
  end
  # End ModelDataClassMixins

  # instance mixins
  module ModelDataInstanceMixins
    def get_directly_contained_objects(child_relation_type, where_clause = nil)
      parent_id = IDInfoTable.get_id_from_id_handle(id_handle)
      self.class.get_objects(ModelHandle.new(id_handle[:c], child_relation_type), where_clause, parent_id: parent_id)
    end

    def get_directly_contained_object_ids(child_relation_type, where_clause = nil)
      self.class.get_object_ids_wrt_parent(child_relation_type, id_handle, where_clause)
    end

    def display_name
      self[:display_name] || get_field?(:display_name)
    end

    def to_s
      display_name || 'UNKNOWN'
    end

    def get_qualified_ref
      # first check if have ref attribute (which is more efficient)
      return DB.ret_qualified_ref_from_scalars(self) if self[:ref]
      IDInfoTable.get_row_from_id_handle(id_handle).ret_qualified_ref()
    end

    def get_obj_name
      @relation_type
    end

    def get_parent_object(opts = {})
      self.class.get_parent_object(id_handle, opts)
    end

    private

    def ret_id_handle_from_db_id(db_id, relation_type)
      IDHandle[c: @c, id: db_id, model_name: relation_type]
    end

    def get_object_from_db_id(db_id, relation_type, _opts = {})
      self.class.get_object(ret_id_handle_from_db_id(db_id, relation_type))
    end
  end
  # End ModelDataInstanceMixins
end
