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
 module DTK
  class ModelInit
    toplevel_model_files = %w(model user user_group user_group_relation repo repo_user repo_remote repo_user_acl attribute attribute_override port port_link monitoring_item attribute_link node node_group node_group_relation component component_ref component_type_hierarchy assembly library target task task_log task_event task_error state_change search_object dependency component_order constraints violation layout component_database link_def link_def component_relation file_asset implementation project node_binding_ruleset dns component_title module_ref module common_module workspace namespace node_bindings node_image node_image_attribute node_interface action_def service service_associations attribute_link_to attribute_link_from)

    toplevel_model_files.each { |model_file| require_relative(model_file) }

    # associate database handle DBInstance with all models
    model_names = Model.initialize_all_models(DBinstance)
  end
end
