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

    def generate_new_service_name(assembly_template, service_module)
      assembly_name = assembly_template.display_name
      name_seed = "#{service_module.display_name}#{NEW_SERVICE_NAME_DELIM}#{assembly_name}"
      name_seed_regex = Regexp.new("^#{name_seed}(.*$)")
      matches = ::DTK::Assembly::Instance.get(service_module.model_handle(:assembly_instance)).select do |assembly|
        assembly[:display_name] =~ name_seed_regex
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
  end
end
