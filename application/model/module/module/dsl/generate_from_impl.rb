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
# TODO: Marked for removal [Haris] - Probably needed but better check
module DTK; class ModuleDSL
  class GenerateFromImpl
    r8_nested_require('generate_from_impl', 'dsl_object')
    def self.create(integer_version = nil)
      integer_version ||= ModuleDSL.default_integer_version()
      unless SupportedIntegerVersions.include?(integer_version)
        fail Error.new("Unexpected integer version (#{integer_version})")
      end
      new(integer_version)
    end
    SupportedIntegerVersions = [1, 2, 3, 4]

    def initialize(integer_version)
      @integer_version = integer_version
    end
    private :initialize

    def generate_refinement_hash(parse_struct, module_name, impl_idh)
      context = {
        integer_version: @integer_version,
        module_name: module_name,
        config_agent_type: parse_struct.config_agent_type,
        implementation_id: impl_idh.get_id()
      }
      DSLObject.new(context).create(:module, parse_struct)
    end

    def self.save_dsl_info(meta_info_hash, impl_mh)
      # TODO: check
      fail Error.new("Need to cehck if meta_info_hash['version'] is right call")
      integer_version = meta_info_hash['version']
      config_agent_type = meta_info_hash['config_agent_type']
      module_name = meta_info_hash['module_name']
      components = meta_info_hash['components']
      impl_id = meta_info_hash['implementation_id']
      module_hash = {
        required: true,
        type: 'module',
        def: { 'components' => components }
      }
      impl_obj = impl_mh.createIDH(id: impl_id).create_object().update_object!(:id, :display_name, :type, :repo_id, :repo, :library_library_id)
      impl_idh = impl_obj.id_handle
      library_idh = impl_idh.createIDH(model_name: :library, id: impl_obj[:library_library_id])
      repo_obj = Model.get_obj(impl_idh.createMH(:repo), cols: [:id, :local_dir], filter: [:eq, :id, impl_obj[:repo_id]])

      dsl_generator = create(integer_version)
      object_form = dsl_generator.reify(module_hash, module_name, config_agent_type)
      r8meta_hash = object_form.render_hash_form()

      r8meta_path = "#{repo_obj[:local_dir]}/r8meta.#{config_agent_type}.yml"
      r8meta_hash.write_yaml(STDOUT)
      File.open(r8meta_path, 'w') { |f| r8meta_hash.write_yaml(f) }

      # this wil add any file_assets that have not been yet added (this will include the r8meta file
      impl_obj.create_file_assets_from_dir_els()

      add_components_from_r8meta(library_idh, config_agent_type, impl_idh, r8meta_hash)

      impl_obj.add_contained_files_and_push_to_repo()
    end

    def reify(hash, module_name, config_agent_type)
      context = {
        integer_version: @integer_version,
        # TODO: do we neeed module_name and :config_agent_type for reify?
        module_name: module_name,
        config_agent_type: config_agent_type
      }
      DSLObject.new(context).reify(hash)
    end
  end
end; end