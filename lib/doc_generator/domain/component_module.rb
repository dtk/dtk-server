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
module DTK; class DocGenerator; class Domain
  class ComponentModule < self
    def self.normalize_top(parsed_dsl__component_module)
      dsl = parsed_dsl__component_module # for succinctness
      input = Input.new(raw: dsl.raw_hash, normalized: dsl.version_normalized_hash)
      { :module => normalize(input) }
    end
    
    def initialize(input)
      raw_input = input.hash(:raw)
      @name        = raw_input.scalar(:module)
      @dsl_version = raw_input.scalar(:dsl_version)
      @components  = raw_input.array(:components).map { |component| Component.normalize(raw_input(component)) }
    end
  
    private

    class Component < self
      def initialize(input)
        raw_input = input.hash(:raw)
        base(raw_input)
        @attributes = raw_input.array(:attributes).map { |attr| Attribute.normalize(raw_input(attr)) }
      end
    end
    
    class Attribute < self
      def initialize(input)
        raw_input = input.hash(:raw)
        base(raw_input)
        @type = raw_input.scalar(:type)
        @required = raw_input.scalar(:required)
      end
    end
  end

end; end; end