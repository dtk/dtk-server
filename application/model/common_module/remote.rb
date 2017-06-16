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
  class CommonModule
    module Remote
      # opts can have keys:
      #  :remote_repo_base 
      #  :namespace
      def self.list(rsa_pub_key, opts = {})
        remote_repo = Repo::Remote.new(opts[:remote_repo_base])
        list_opts = { ret_versions_array: true, namespace: opts[:namespace] }
        remote_service_modules = remote_repo.list_module_info(:service_module, rsa_pub_key, list_opts)
        remote_component_modules = remote_repo.list_module_info(:component_module, rsa_pub_key, list_opts)
        Intersect.intersect_remote_lists(remote_service_modules, remote_component_modules)
      end

      # opts can have keys:
      #   :donot_raise_error
      def self.get_module_info(project, remote_params, client_rsa_pub_key, opts = {})
        ret = {}
        if raw_service_info = Info::Service::Remote.get_module_info?(project, client_rsa_pub_key, remote_params, opts)
          ret.merge!(service_info: transform_from_raw_remote_module_info(raw_service_info))
        end
        if raw_component_info = Info::Component::Remote.get_module_info?(project, client_rsa_pub_key, remote_params, opts)
          ret.merge!(component_info: transform_from_raw_remote_module_info(raw_component_info))
        end
        
        unless ret.empty?
          ret.merge(version: remote_params.version || Intersect.intersect_versions(raw_service_info, raw_component_info))
        else
          if opts[:donot_raise_error]
            ret
          else
            fail ErrorUsage, "Module '#{remote_params.pp_module_ref}' not found in the #{Term.remote_ref}"
          end
        end     
      end

      def self.publish(project, local_params, remote_params, client_rsa_pub_key)
        remote_module_info = get_module_info(project, remote_params, client_rsa_pub_key, donot_raise_error: true)
        something_published = false

        unless remote_module_info[:component_info]
          something_published = Info::Component::Remote.publish?(project, local_params, remote_params, client_rsa_pub_key)
        end

        unless remote_module_info[:service_info] 
          if Info::Service::Remote.publish?(project, local_params, remote_params, client_rsa_pub_key)
            something_published = true
          end
        end

        fail ErrorUsage, "The publish command failed because the module '#{remote_params.pp_module_ref}' is already on the #{Term.remote_ref}"  unless something_published
        nil
      end

      def self.delete(project, remote_params, client_rsa_pub_key, force_delete, opts = {})
        # for now we delete service and component modules from remote if exist
        # later will change to unpublish for common module
        if versions = opts[:versions]
          versions.each do |version|
            remote_params[:version] = version
            delete_remote_version?(project, remote_params, client_rsa_pub_key, force_delete)
          end
        else
          delete_remote_version?(project, remote_params, client_rsa_pub_key, force_delete)
        end

        nil
      end

      def self.install_on_server(project, local_params, remote_params, client_rsa_pub_key, opts = {})
        remote_module_info = get_module_info(project, remote_params, client_rsa_pub_key, donot_raise_error: true)
        namespace   = local_params.namespace
        module_name = local_params.module_name
        version     = local_params.version

        if CommonModule.exists(project, :common_module, namespace, module_name, version)
          fail ErrorUsage, "Module '#{local_params.pp_module_ref}' exists already"
        end

        if remote_module_info[:component_info]
          cmp_remote_params = remote_params.merge(module_type: :component_module)
          cmp_local_params  = local_params.merge(module_type: :component_module)
          CommonModule::Info::Component::Remote.install(project, cmp_local_params, cmp_remote_params, client_rsa_pub_key)
        end

        if remote_module_info[:service_info]
          sm_remote_params = remote_params.merge(module_type: :service_module)
          sm_local_params  = local_params.merge(module_type: :service_module)
          CommonModule::Info::Service::Remote.install(project, sm_local_params, sm_remote_params, client_rsa_pub_key)
        end

        dtk_dsl_parse_helper = nil
        Model.Transaction do
          common_module_local    = local_params.create_local(project)
          component_module_local = common_module_local.merge(module_type: :component_module)
          service_module_local   = common_module_local.merge(module_type: :service_module)
          common_module_repo     = CommonModule.create_repo(common_module_local, no_initial_commit: true, delete_if_exists: true)
          common_module_branch   = CommonModule.create_module_and_branch_obj?(project, common_module_repo.id_handle, common_module_local, opts.merge(return_module_branch: true))
          RepoRemote.create_repo_remote?(project.model_handle(:repo_remote), module_name, common_module_repo.display_name, namespace, common_module_repo.id, set_as_default_if_first: true)

          dtk_dsl_transform_class = ::DTK::DSL::ServiceAndComponentInfo::TransformFrom
          dtk_dsl_parse_helper = dtk_dsl_transform_class.new(namespace, module_name, version)

          if remote_module_info[:service_info]
            aug_service_module_branch = Info::Service.get_augmented_module_branch_from_local(service_module_local)
            Info::Service.transform_from_service_info(common_module_branch, aug_service_module_branch, { dtk_dsl_parse_helper: dtk_dsl_parse_helper })
          end

          if remote_module_info[:component_info]
            Info::Component.populate_common_module_repo_from_component_info(component_module_local, common_module_branch, common_module_repo, { dont_create_file: true, dtk_dsl_parse_helper: dtk_dsl_parse_helper })
          end

          file_path__content_array = []
          dtk_dsl_parse_helper.output_path_text_pairs.each_pair do |path, text_content|
            file_path__content_array << { path: path, content: text_content }
          end

          CommonDSL::Generate::DirectoryGenerator.add_files(common_module_branch, file_path__content_array, donot_push_changes: true, no_commit: true)
          RepoManager.add_all_files_and_commit({ commit_msg: 'Loaded module info' }, common_module_branch)
          common_module_branch.push_changes_to_repo
        end

        install_dependent_modules(dtk_dsl_parse_helper, local_params, remote_params, project, client_rsa_pub_key) if dtk_dsl_parse_helper
      end

      private

      def self.install_dependent_modules(dtk_dsl_parse_helper, local_params, remote_params, project, client_rsa_pub_key)
        if dsl_file_content = dtk_dsl_parse_helper.output_path_hash_pairs[common_module_dsl_file_path]
          if dependencies = dsl_file_content["dependencies"]
            dependencies.each_pair do |dep_name, dep_version|
              cmp_namespace, cmp_name = dep_name.split('/')
              unless CommonModule.exists(project, :component_module, cmp_namespace, cmp_name, dep_version)
                cmp_module_local =  local_params.merge(module_type: :component_module, module_name: cmp_name, namespace: cmp_namespace, version: dep_version)
                cmp_module_remote = remote_params.merge(module_type: :component_module, module_name: cmp_name, namespace: cmp_namespace, version: dep_version)
                CommonModule::Info::Component::Remote.install(project, cmp_module_local, cmp_module_remote, client_rsa_pub_key)
              end
            end
          end
        end
      end

      def self.common_module_dsl_file_path
        common_module_file_type.canonical_path
      end

      def self.common_module_file_type
        @common_module_file_type ||= ::DTK::CommonDSL::FileType::CommonModule::DSLFile::Top
      end

      def self.delete_remote_version?(project, remote_params, client_rsa_pub_key, force_delete)
        remote_opts = { raise_error: false, skip_accessibility_check: true }
        remote_params[:module_type] = :component_module
        component_info = ComponentModule.delete_remote(project, remote_params, client_rsa_pub_key, force_delete, remote_opts)

        remote_params[:module_type] = :service_module
        service_info = ServiceModule.delete_remote(project, remote_params, client_rsa_pub_key, force_delete, remote_opts)

        fail(ErrorUsage, "Module '#{remote_params.pp_module_ref}' not found in the DTKN Catalog") if component_info.empty? && service_info.empty?
      end

      module Term
        def self.remote_ref
          'DTKN Catalog'
        end
      end
    
      def self.transform_from_raw_remote_module_info(raw_info)
        { remote_repo_url: raw_info[:remote_repo_url] }
      end

      module Intersect
        # TODO: DTK-2766: consider handling condition where service module at some version x requires component module
        #       at another version; in this case want to use the different versions of these modules.
        #       Need to figure out best version to use for combined; default is the service module version
        #       Alternative is to fix up modules that have different versions
        def self.intersect_versions(raw_service_info, raw_component_info)
          if raw_service_info
            if raw_component_info
              if raw_service_info[:latest_version] == raw_component_info[:latest_version]
                raw_service_info[:latest_version]
              else
                Aux.latest_version?(raw_service_info[:versions] && raw_component_info[:versions]) || 
                  fail(ErrorUsage, "Mismatch between component info and service info versions")
              end
            else
              raw_service_info[:latest_version]
            end
          elsif raw_component_info
            raw_component_info[:latest_version]
          else
            fail ErrorUsage, "Unexpected that both raw_component_info and raw_component_info are nil"
          end
        end
        
        def self.intersect_remote_lists(remote_service_modules, remote_component_modules)
          ndx_service_modules = remote_service_modules.inject({}) { |h, m| h.merge(m[:display_name] => m) }
          ndx_component_modules = remote_component_modules.inject({}) { |h, m| h.merge(m[:display_name] => m) }
          all_module_names = (ndx_service_modules.keys + ndx_component_modules.keys).uniq.sort
          all_module_names.map do |module_name|
            service_module = ndx_service_modules[module_name]
            component_module = ndx_component_modules[module_name]
            if service_module and component_module
              intersect_matching_list_elements(service_module, component_module)
            else
              service_module || component_module
            end
          end
        end
          
        private        
        
        def self.intersect_matching_list_elements(service_module, component_module)
          {
            display_name: service_module[:display_name],
            owner: owner(service_module, component_module),
            group_owners: group_owners(service_module, component_module),
            permissions: permissions(service_module, component_module),
            last_updated: last_updated(service_module, component_module),
            versions: versions(service_module, component_module)
          }
        end
        
        def self.last_updated(service_module, component_module)
          service_last_updated   = service_module[:last_updated]
          component_last_updated = component_module[:last_updated]
          if service_last_updated and component_last_updated
            if DateTime.parse(service_last_updated) < DateTime.parse(component_last_updated)
              component_last_updated
            else
              service_last_updated
            end
          else
            service_last_updated || component_last_updated
          end
        end
        
        def self.versions(service_module, component_module)
          Aux.sort_versions((service_module[:versions] || [])  & (component_module[:versions] || []))
        end
        
        # TODO: just hacls now if service modules and component_modules conflict on owner, :group_owners, or permisions
        def self.owner(service_module, component_module)
          service_module[:owner]
        end
        
        def self.group_owners(service_module, component_module)
          service_module[:group_owners]
        end
        
        def self.permissions(service_module, component_module)
          # TODO: intersect 
          service_module[:permissions]
        end

      end
    end
  end
end

