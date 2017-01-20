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
  class Component::Domain
    module Provider
      class Parameters < Component::Domain
        def initialize(component)
          super(component)
        end

        def attributes_with_overrides(overrides)
          # normalize in case keys are symbols
          overrides = overrides.inject({}) { |h, (a, v)| h.merge(a.to_s => v) }
          attributes.map do |attribute|
            el = attribute
            if attribute[:attribute_value].nil?
              override_val = overrides[attribute.display_name]
              el = el.merge(attribute_value: override_val) unless override_val.nil?
            end
            el
          end
        end
      end
    end
  end
end

