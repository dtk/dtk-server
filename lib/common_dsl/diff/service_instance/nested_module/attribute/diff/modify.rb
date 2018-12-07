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
    class Diff
      module ServiceInstance
        class NestedModule
            class Attribute
                class Diff
                  class Modify 
                    include Mixin
                    def self.process(component, old_attribute, attribute_value, extra_fields = {})
                      new_attribute = { 
                        id: old_attribute.id,
                        value_asserted: attribute_value,
                        value_derived: nil
                      }.merge(extra_fields)
                      attr_mh = old_attribute.id_handle.createMH(model_name: :attribute, parent_model_name: :component)
                      modified_rows = [new_attribute]
                      Model.update_from_rows(attr_mh, modified_rows)
                    end
                  end
                end
            end
        end
      end
    end
end; end
