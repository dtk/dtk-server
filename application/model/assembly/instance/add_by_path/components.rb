#
# Copyright (C) 2010-2017 dtk contributors
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
module DTK; class Assembly::Instance
  module AddByPath
    module Components
      def self.add(service_instance, params, opts = {})
        component_name = params[:name]
        content = params[:content]

        assembly_instance = service_instance.copy_as_assembly_instance
        dsl_version       = service_instance.get_service_instance_branch.dsl_version

        diff_result = ::DTK::CommonDSL::Diff::Result.new({})
        module_branch = assembly_instance.get_service_instance_branch
        # base_diffs = CommonDSL::Diff::ServiceInstance::DSL.compute_base_diffs?(service_instance, content, components_content_input, {})
        service_instance_gen   = CommonDSL::Generate::ServiceInstance.generate_canonical_form(service_instance, module_branch)
        assembly_gen   = service_instance_gen.req(:Assembly)
        # components_gen = assembly_gen.req(:Components)

        content_hash = CommonDSL::ObjectLogic::ContentInputHash.new(content)
        content_hash = CommonDSL::Parse::CanonicalInput::Hash.new
        content_hash.merge!(component_name => content)

        # base_diffs = assembly_gen.diff?(content_hash, CommonDSL::Diff::QualifiedKey.new, service_instance: service_instance, impacted_files: {})

        diff_set = CommonDSL::Diff::Set.new(qualified_key: CommonDSL::Diff::QualifiedKey.new, service_instance: service_instance)


        # diff_set = XYZ::CommonDSL::ObjectLogic::Assembly::Component.diff_set(gen_object, parse_object, @qualified_key, service_instance: @service_instance, impacted_files: @impacted_files)
        base_diffs = XYZ::CommonDSL::ObjectLogic::Assembly::Component.diff_set( CommonDSL::Parse::CanonicalInput::Hash.new, content_hash, CommonDSL::Diff::QualifiedKey.new, service_instance: service_instance, impacted_files: {})

        base_diffs.add_diff_set? CommonDSL::ObjectLogic::Assembly::Component::Attribute, CommonDSL::Parse::CanonicalInput::Hash.new, content[:attributes]
        # base_diffs = diff_set.add_diff_set? CommonDSL::ObjectLogic::Assembly::Component, CommonDSL::Parse::CanonicalInput::Hash.new, content_hash
        collated_diffs = base_diffs.collate
        diff_result.semantic_diffs = collated_diffs.serialize(dsl_version)
        CommonDSL::Diff::ServiceInstance::DSL.process_diffs(diff_result, collated_diffs, module_branch, service_instance_gen, dependent_modules: {}, service_instance: service_instance, impacted_files: {}, service_instance_parse: content_hash)

        # base_diffs = assembly_gen.diff?(content_hash, CommonDSL::Diff::QualifiedKey.new, service_instance: service_instance, impacted_files: {})
        # if collated_diffs = base_diffs.collate
          # diff_result.semantic_diffs = collated_diffs.serialize(dsl_version)
          # CommonDSL::Diff::ServiceInstance::DSL.process_diffs(diff_result, collated_diffs, module_branch, service_instance_gen, dependent_modules: service_instance_parse[:dependent_modules], service_instance: service_instance, impacted_files: impacted_files, service_instance_parse: service_instance_parse)
        # end
      end
    end
  end
end; end