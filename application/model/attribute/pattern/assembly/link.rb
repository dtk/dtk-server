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
  class Assembly
    class Link < self
      r8_nested_require('link', 'source')
      r8_nested_require('link', 'target')

      class Info
        def initialize(parsed_adhoc_links, dep_component_instance, antec_component_instance)
          @links = parsed_adhoc_links
          @dep_component_instance = dep_component_instance
          @antec_component_instance = antec_component_instance
          @meta_update_supported = (!dep_component_instance.nil? && !antec_component_instance.nil?)
        end
        attr_reader :links, :dep_component_instance, :antec_component_instance
        def meta_update_supported?
          @meta_update_supported
        end

        def dep_component_template
          @dep_component_template ||= @dep_component_instance.get_component_template_parent()
        end

        def antec_component_template
          @antec_component_template ||= @antec_component_instance.get_component_template_parent()
        end
      end

      # returns object of type Info
      def self.parsed_adhoc_link_info(parent, assembly, target_attr_term, source_attr_term)
        assembly_idh = assembly.id_handle()
        target_attr_pattern = Target.create_attr_pattern(assembly, target_attr_term)
        if target_attr_pattern.attribute_idhs.empty?
          fail ErrorUsage.new("No matching attribute to context term (#{target_attr_term})")
        end
        source_is_antecdent = !target_attr_pattern.is_antecedent?()
        source_attr_pattern = Source.create_attr_pattern(assembly, source_attr_term, source_is_antecdent)
        unless source_component_instance = source_attr_pattern.component_instance
          fail DSLNotSupported::LinkToNonComponent.new()
        end
        source_component_instance = source_attr_pattern.component_instance
        if source_component_instance[:component_type] == target_attr_pattern.component_instance[:component_type]
          fail DSLNotSupported::LinkBetweenSameComponentTypes.new(source_component_instance)
        end

        # TODO: need to do more checking and processing to include:
        #  if has a relation set already and scalar conditionally reject or replace
        # if has relation set already and array, ...
        attr_info = {
          assembly_id: assembly_idh.get_id(),
          output_id: source_attr_pattern.attribute_idh.get_id()
        }
        if fn = source_attr_pattern.fn()
          attr_info.merge!(function: fn)
        end

        parsed_adhoc_links = target_attr_pattern.attribute_idhs.map do |target_attr_idh|
          hash = attr_info.merge(input_id: target_attr_idh.get_id())
          parent.new(hash, target_attr_pattern.attribute_pattern, source_attr_pattern)
        end
        dep_cmp, antec_cmp = determine_dep_and_antec_components(target_attr_pattern, source_attr_pattern)
        Info.new(parsed_adhoc_links, dep_cmp, antec_cmp)
      end

      private

      def self.determine_dep_and_antec_components(target_attr_pattern, source_attr_pattern)
        unless target_cmp = target_attr_pattern.component_instance()
          fail Error.new('Unexpected that target_attr_pattern.component() is nil')
        end
        source_cmp = source_attr_pattern.component_instance()

        antec_cmp, dep_cmp =
          if target_attr_pattern.is_antecedent?()
            [target_cmp, source_cmp]
          else
            [source_cmp, target_cmp]
          end
        [dep_cmp, antec_cmp]
      end
    end
  end
end; end