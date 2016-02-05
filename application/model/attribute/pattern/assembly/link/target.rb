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
module DTK; class Attribute::Pattern
  class Assembly; class Link
    class Target < self
      def self.create_attr_pattern(base_object, target_attr_term)
        attr_pattern = super(base_object, strip_special_symbols(target_attr_term))
        new(attr_pattern, target_attr_term)
      end

      attr_reader :attribute_pattern
      def attribute_idhs
        @attribute_pattern.attribute_idhs()
      end

      def component_instance
        @attribute_pattern.component_instance()
      end

      def is_antecedent?
        @is_antecedent
      end

      private

      def initialize(attr_pattern, target_attr_term)
        @attribute_pattern = attr_pattern
        @is_antecedent = compute_if_antecedent?(target_attr_term)
      end

      def compute_if_antecedent?(target_attr_term)
        !!(target_attr_term =~ /^\*/)
      end
      def self.strip_special_symbols(target_attr_term)
        target_attr_term.gsub(/^\*/, '')
      end
    end
  end; end
end; end