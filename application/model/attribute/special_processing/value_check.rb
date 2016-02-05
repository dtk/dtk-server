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
module DTK; class Attribute
  class SpecialProcessing
    class ValueCheck < self
      # returns [whether_special_processing,nil_or_value_check_error]
      def self.error_special_processing?(attr, new_val)
        error = nil
        if attr_info = needs_special_processing?(attr)
          error = error?(attr, attr_info, new_val)
        end
        special_processing = (not attr_info.nil?)
        [special_processing, error]
      end

      private

      def self.error?(attr, attr_info, new_val)
        if legal_values = LegalValues.create?(attr, attr_info)
          unless legal_values.include?(new_val)
            LegalValue::Error.new(attr, new_val, legal_values: legal_values.print_form)
          end
        end
      end
    end
  end
end; end