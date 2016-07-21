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
module DTK; class CommonModule::DSL::Generate::ContentInput
  class Assembly
    class Component
      class Attribute < Assembly::Attribute

        def initialize(type, attribute, opts = {})
          super(type, attribute)
          fail Error, "Missing opts[:component]" unless opts[:component]
          @component = opts[:component]
        end
        private :initialize

        # TODO: debug
        def generate_content_input?
          ret = super
          unless @attribute.get_field?(:hidden)
            unless tags.empty?
              pp [:attribute, merge(TAGS: tags)]
            end
          end
          ret
        end

        private

        def prune? 
          attribute_value.nil? or is_title_attribute?
        end

        def tags?
          # assumption that @attribute has keys :hidden, 
          ret = []
          derivation_type = @attribute.derivation_type
          derivation_tag = 
            case derivation_type
            when :asserted, :derived__default, :derived__propagated
              derivation_type
            else
              Log.error("Unexpected derivation type '#{derivation_type}'")
              nil
            end

          ret << derivation_tag if derivation_tag
          ret << :hidden if @attribute.get_field?(:hidden)
          ret.empty? ? nil : ret
        end

        def is_title_attribute?
          # @component[:only_one_per_node] is check just for efficiency
          (not @component[:only_one_per_node]) and @attribute.is_title_attribute?
        end
        
      end
    end
  end
end; end
