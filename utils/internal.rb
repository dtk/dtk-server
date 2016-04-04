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
files =
  %w(dynamic_loader aux sql aes dataset_from_search_pattern hash_object opts array_object rest_uri serialize_to_json import_export semantic_type workflow command_and_control config_agent cloud_connect view_def_processor repo_manager parse_log current_session create_thread eventmachine_helper extract action_results_queue simple_action_queue async_response output_table rubygems_checker hierarchical_tags puppet_forge mustache_template data_encryption)
r8_nested_require('internal', files)

r8_nested_require('internal/workflow/adapters', 'agent_grit_adapter')


