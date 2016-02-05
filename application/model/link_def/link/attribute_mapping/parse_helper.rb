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
module DTK; class LinkDef::Link; class AttributeMapping
  module ParseHelper
    module VarEmbeddedInText
      def self.isa?(am)
        if output_term_index = (am[:output] || {})[:term_index]
          if output_var = output_term_index.split('.').last
            # example abc${output_var}def",
            if output_var =~ /(^[^\$]*)\$\{[^\}]+\}(.*$)/
              text_parts = [Regexp.last_match(1), Regexp.last_match(2)]
              {
                name: :var_embedded_in_text,
                constants: { text_parts: text_parts }
              }
            end
          end
        end
      end
    end
  end
end; end; end