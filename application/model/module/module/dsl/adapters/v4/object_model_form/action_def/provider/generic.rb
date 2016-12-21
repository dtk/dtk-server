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
  class ModuleDSL::V4::ObjectModelForm::ActionDef::Provider
    class Generic < self
      module Constant
        module Variations
        end
        extend Aux::ParsingingHelper::ClassMixin
      end

      def self.type
        :generic
      end

      def self.matches_input_hash?(input_hash)
        true
      end
      
      def provider_specific_fields(input_hash)
        input_hash.inject({}) { |h, (k, v)| h.merge(k.to_sym => v) }
      end
    end
  end
end
