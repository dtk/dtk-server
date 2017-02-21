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
module DTK; module CommonDSL::ObjectLogic
  class Assembly
    class Component
      class Attribute < Assembly::Attribute

        def initialize(type, attribute, opts = {})
          super(type, attribute)
          fail Error, "Missing opts[:component]" unless opts[:component]
          @component = opts[:component]
        end
        private :initialize

        private

        def prune? 
          is_title_attribute?
        end

        def tags?
          ret = []
          # checking for whether attribute a desired state or actual state (dynamic)
          # and if derived whether asserted or derived from default or propagation
          if @attribute.get_field?(:dynamic)
            ret << :actual
          else
            if desired_state_tag = desired_state_tag? 
              ret << desired_state_tag
            end
          end
          ret << :hidden if @attribute.get_field?(:hidden)
          ret.empty? ? nil : ret
        end

        def desired_state_tag?
          derivation_type = @attribute.derivation_type
          case derivation_type
          when :asserted, :derived__default, :derived__propagated
            "desired__#{derivation_type}".to_sym
          else
            Log.error("Unexpected derivation type '#{derivation_type}'")
            nil
          end
        end

        def is_title_attribute?
          # @component[:only_one_per_node] is check just for efficiency
          (not @component[:only_one_per_node]) and @attribute.is_title_attribute?
        end
        
      end
    end
  end
end; end
