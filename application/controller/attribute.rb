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
# TODO: Marked for removal [Haris] - Move logic to other controller
module DTK
  class AttributeController < AuthController
    def rest__set
      attr_type = ret_non_null_request_params(:attribute_type)
      attribute_id, attribute_value, module_id = ret_non_null_request_params(:attribute_id, :attribute_value, "#{attr_type}_id".to_sym)
      attribute_instance = Attribute.get_attribute_from_identifier(attribute_id, model_handle(), module_id)
      # attribute_instance = id_handle(attribute_id, :attribute).create_object(:model_name => :attribute)
      attribute_instance.set_attribute_value(attribute_value)

      rest_ok_response(attribute_id: attribute_id)
    end
  end
end