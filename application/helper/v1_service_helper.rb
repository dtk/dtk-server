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
module Ramaze::Helper
  module V1ServiceHelper

    NEW_SERVICE_NAME_DELIM = '-'
    NEW_SERVICE_INDEX_REGEXP = Regexp.new("^#{NEW_SERVICE_NAME_DELIM}([0-9]+$)")

    def service_instance
      ::DTK::CommonModule::ServiceInstance.new(assembly_instance)
    end

    def assembly_instance
      create_obj([:service_id, :service_instance], ::DTK::Assembly::Instance)
    end

    def external_assembly_instance(param)
      create_obj(param, ::DTK::Assembly::Instance)
    end

    def format_yaml_response(response)
      attributes_content_input = {}
      response.each do |attribute| 
        attributes_content_input[attribute[:display_name]] = attribute[:value] || {} 
      end
      top_level_content_input  = ::DTK::CommonDSL::ObjectLogic::ContentInputHash.new('attributes' => attributes_content_input)
      dsl_version  = service_instance.get_service_instance_branch.dsl_version
      yaml_content = ::DTK::CommonDSL::Generate::FileGenerator.generate_yaml_text(:workflow, top_level_content_input, dsl_version)
      hash_content = YAML.load(yaml_content)
    end

    def matches_existing_assembly_instance?(service_name, assembly_template)
      matches = existing_assembly_instances(assembly_template.model_handle(:assembly_instance)).select do |assembly_instance|
        assembly_instance.display_name == service_name
      end
      !matches.empty?
    end

    def generate_new_service_name(assembly_template, service_module)
      assembly_name = assembly_template.display_name
      name_seed = "#{service_module.display_name}#{NEW_SERVICE_NAME_DELIM}#{assembly_name}"
      name_seed_regex = Regexp.new("^#{name_seed}(.*$)")
      matches = existing_assembly_instances(assembly_template.model_handle(:assembly_instance)).select do |assembly_instance|
        assembly_instance.display_name =~ name_seed_regex
      end

      if matches.empty?
        name_seed
      else
        higest_index = 2
        matches.each do |match|
          match[:display_name] =~ name_seed_regex
          index_part = $1
          if index_part =~ NEW_SERVICE_INDEX_REGEXP
            new_index = $1.to_i + 1
            higest_index = new_index if new_index > higest_index
          end
        end
        "#{name_seed}#{NEW_SERVICE_NAME_DELIM}#{higest_index}"
      end
    end

    def existing_assembly_instances(assembly_instance_mh)
      ::DTK::Assembly::Instance.get(assembly_instance_mh)
    end

  end
end
