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
  module AutoImport
    def get_required_and_missing_modules(project, remote_params, client_rsa_pub_key = nil)
      remote = remote_params.create_remote(project)
      response = Repo::Remote.new(remote).get_remote_module_components(client_rsa_pub_key)
      opts = Opts.new(project_idh: project.id_handle())

      # this method will return array with missing and required modules
      module_info_array = self.cross_reference_modules(opts, response['component_info'], remote.namespace, response['dependency_warnings'])
    end

    # Method will check if given component modules are present on the system
    # returns [missing_modules, found_modules]
    def cross_reference_modules(opts, required_modules, service_namespace = nil, dependency_warnings = nil)
      project_idh = opts.required(:project_idh)

      required_modules ||= []
      req_names = required_modules.collect { |m| m['module_name'] }

      missing_modules = []
      found_modules = []

      required_modules.each do |r_module|
        name      = r_module['module_name']
        type      = r_module['module_type']
        version   = r_module['version_info']
        url       = r_module['module_url']
        # we support both fields for namespace
        namespace = r_module['remote_namespace'] || r_module['module_namespace']

        i_modules = installed_modules(type.to_sym, project_idh)
        is_found  = false

        i_modules.each do |i_module|
          branches = i_module.get_module_branches
          versions = []

          if branches.size == 1
            versions << branches.first[:version]
          else
            branches.each {|br| versions << br[:version] }
          end

          matching_version = match_versions(versions, version, i_module)
          is_found = i_module if name.eql?(i_module.display_name) && matching_version && (namespace.nil? || namespace.eql?(i_module.module_namespace))
        end

        data = data_element(name, namespace || service_namespace, type, version, url)

        if is_found
          branch = is_found.get_workspace_branch_info(version)
          data.merge!(frozen: branch[:frozen])
          found_modules << data
        else
          missing_modules << data
        end
      end

      # delete modules that are alreafy installed
      if dependency_warnings
        dependency_warnings.reject! do |el|
          reject_it = false
          if el['error_type'].eql?('not_found')
            installed = installed_modules(el['module_type'], project_idh)
            installed.each do |i_module|
              # does it match name and namespace
              installed_name = i_module.display_name
              installed_ns   = i_module.module_namespace

              if (el['module_name'].eql?(installed_name) && el['module_namespace'].eql?(installed_ns))
                found_modules << data_element(installed_name, installed_ns, el['module_type'])
                reject_it = true
                break
              end
            end
          end

          reject_it
        end
      end

      # important
      clear_cached()

      [missing_modules, found_modules, dependency_warnings]
    end

    private

    def data_element(name, namespace, type, version = nil, url = nil)
      { name: name, version: version, type: type, namespace: namespace, module_url: url }
    end

    def clear_cached
      @cached_module_list = {}
    end

    def installed_modules(type, project_idh)
      @cached_module_list ||= {}

      type = type.to_sym

      unless @cached_module_list[type]
        sp_hash = {
          cols: [:id, :display_name, :namespace].compact,
          filter: [:eq, :project_project_id, project_idh.get_id()]
        }
        mh = project_idh.createMH(type)
        @cached_module_list[type] = get_objs(mh, sp_hash)
      end

      @cached_module_list[type]
    end

    def match_versions(versions, version, i_module)
      if versions.empty?
        ModuleVersion.versions_same?(version, i_module.fetch(:module_branch, {})[:version])
      else
        versions.each do |vr|
          return true if ModuleVersion.versions_same?(version, vr)
        end
        false
      end
    end
  end
end