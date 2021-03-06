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
r8_require("#{::R8::Config[:sys_root_path]}/repo_manager_client/lib/repo_manager_client")
module DTK
  class Repo
    class Remote
      require_relative('remote/auth')
      include AuthMixin

      DISPLAY_NAME_FOR_MASTER_BRANCH = 'master'

      def initialize(remote_or_repo_base = nil)
        arg = remote_or_repo_base #for succinctness
        if ModuleBranch::Location::Remote.includes?(arg)
          @remote = arg
          @project = @remote.project
          @remote_repo_base = @remote.remote_repo_base
        elsif arg
          @remote_repo_base = arg.to_sym
        end

        @client = RepoManagerClient.new
        Log.debug "Using repo manager: '#{@client.rest_base_url}'"
      end

      def repoman_client
        client
      end

      def register_catalog_user(username, email, password, first_name = nil, last_name = nil)
        # we also make sure that tenant user is created
        create_tenant_user

        # than we register catalog user
        client.register_catalog_user(username, email, password, first_name, last_name)
      end

      def add_client_access(client_rsa_pub_key, client_rsa_key_name, force_access = false)
        # we also make sure that tenant user is created
        create_tenant_user

        # we add user or his key to reponan
        response = client.add_client_access(client_rsa_pub_key, client_rsa_key_name, force_access)

        response
      end

      def remove_client_access(username)
        client.remove_client_access(username)
      end

      def validate_catalog_credentials!(username, password)
        client.validate_catalog_credentials!(username, password)
      end

      def create_tenant_user
        username        = current_tenant_username
        rsa_pub_key     = dtk_instance_rsa_pub_key
        rsa_key_name    = dtk_instance_remote_repo_key_name

        client.create_tenant_user(username, rsa_pub_key, rsa_key_name)
      end

      def publish_to_remote(client_rsa_pub_key, module_refs_content = nil)
        username = current_tenant_username

        unless namespace = remote.namespace
          namespace = CurrentSession.new.get_user_object.get_namespace
          Log.error("Unexpected that naemspace was null and used CurrentSession.new.get_user_object.get_namespace: #{namespace}}")
        end

        params = {
          username: username,
          name: remote.module_name,
          type: type_for_remote_module(remote.module_type),
          namespace: namespace,
          version: remote.version
        }

        params.merge!(module_refs_content: module_refs_content) unless is_empty?(module_refs_content)

        response_data = client.publish_module(params, client_rsa_pub_key)

        { remote_repo_namespace: namespace }.merge(Aux.convert_keys_to_symbols(response_data))
      end

      def delete_remote_module(client_rsa_pub_key, force_delete = false, opts = {})
        raise_error_if_module_is_not_accessible(client_rsa_pub_key) unless opts[:skip_accessibility_check]
        params = {
          username: current_tenant_username,
          name: remote.module_name,
          namespace: remote.namespace,
          type: type_for_remote_module(remote.module_type),
          force_delete: force_delete
        }
        params.merge!(version: remote.version) if remote.version
        client.delete_module(params, client_rsa_pub_key, opts)
      end

      def raise_error_if_module_is_not_accessible(client_rsa_pub_key)
        get_remote_module_info(client_rsa_pub_key)
      end
      private :raise_error_if_module_is_not_accessible

      def check_remote_exist(client_rsa_pub_key, opts = {})
        client_params = {
          name: remote.module_name,
          type: type_for_remote_module(remote.module_type),
          namespace: remote.namespace,
          rsa_pub_key: client_rsa_pub_key
        }
        client_params.merge!(version: remote.version) if remote.version

        !client.get_module_info?(client_params, raise_error_with_exceptions: opts[:do_not_raise] && [:no_resource]).nil?
      end

      # opts can have keys:
      #   :module_refs_content
      def get_remote_module_info(client_rsa_pub_key, opts = {})
        get_remote_module_info?(client_rsa_pub_key, module_refs_content: opts[:module_refs_content], raise_error: true)
      end
      # opts can have keys:
      #   :module_refs_content
      #   :raise_error
      def get_remote_module_info?(client_rsa_pub_key, opts = {})
        client_params = {
          name: remote.module_name,
          type: type_for_remote_module(remote.module_type),
          namespace: remote.namespace,
          rsa_pub_key: client_rsa_pub_key
        }

        client_params.merge!(version: remote.version) if remote.version
        client_params.merge!(module_refs_content: opts[:module_refs_content]) unless is_empty?(opts[:module_refs_content])

        if ignore_missing_base = opts[:ignore_missing_base_version]
          client_params.merge!(ignore_missing_base_version: ignore_missing_base)
        end

        get_opts = opts[:raise_error] ? { raise_error: true } : { raise_error_with_exceptions: [:no_resource] }
        response_data = client.get_module_info?(client_params, get_opts)
        return nil if response_data.nil?

        ret = Aux.convert_keys_to_symbols(response_data)
        ret.merge!(remote_repo_url: RepoManagerClient.repo_url_ssh_access(ret[:git_repo_name]))
        if remote.version
          # TODO: ModuleBranch::Location:
          # fail Error.new('Not versions not implemented')
          versions = branch_names_to_versions_stripped(ret[:branches])||ret[:versions]
          unless versions && versions.include?(remote.version)
            if opts[:donot_raise_error]
              return
            else
              fail ErrorUsage, "Module '#{remote.pp_module_ref}' not found in the DTKN Catalog"
            end
          end
        end
        ret
      end

      def get_remote_module_components(client_rsa_pub_key = nil)
        params = {
          name: remote.module_name,
          version: remote.version,
          namespace: remote.namespace,
          type: remote.module_type,
          do_not_raise: true,
          dependencies_info: true
        }
        @client.get_components_info(params, client_rsa_pub_key)
      end

      def list_remote_assemblies(client_rsa_pub_key)
        params = {
          name: remote.module_name,
          version: remote.version,
          namespace: remote.namespace,
          type: remote.module_type,
          do_not_raise: true,
          dependencies_info: true
        }
        @client.get_module_assemblies_info(params, client_rsa_pub_key)
      end

      def remote
        @remote || fail(Error, 'Should not be called if @remote is nil')
      end
      private :remote

      # opts can have keys:
      #  :ret_versions_array
      #  :namespace
      def list_module_info(type, rsa_pub_key, opts = {})
        new_repo = R8::Config[:repo][:remote][:new_client]
        filter = { type: type_for_remote_module(type) }
        filter.merge!(namespace: opts[:namespace]) if opts[:namespace]
        remote_modules = client.list_modules(filter, rsa_pub_key)

        unsorted = remote_modules.map do |r|
          el = {}
          last_updated = r['updated_at'] && Time.parse(r['updated_at']).strftime('%Y/%m/%d %H:%M:%S')
          permission_string = "#{r['permission_hash']['user']}/#{r['permission_hash']['user_group']}/#{r['permission_hash']['other']}"
          el.merge!(display_name: r['full_name'], owner: r['owner_name'], group_owners: r['user_group_names'], permissions: permission_string, last_updated: last_updated)
          versions = opts[:ret_versions_array] ? r['versions'] : branch_names_to_versions(r['branches'])

          if versions && !versions.empty?
            # substitute base with master
            parsed_versions = []
            versions.each{ |version| parsed_versions << (version.eql?('master') ? DISPLAY_NAME_FOR_MASTER_BRANCH : version) }
            el.merge!(versions: Aux.sort_versions(parsed_versions))
          end

          el
        end

        unsorted.sort { |a, b| a[:display_name] <=> b[:display_name] }
      end

      def list_module_assemblies_info(type = nil, rsa_pub_key = nil, opts = {})
        new_repo = R8::Config[:repo][:remote][:new_client]
        filter = type && { type: type_for_remote_module(type) }
        remote_modules = client.list_module_assemblies(filter, rsa_pub_key)
      end

      def branch_names_to_versions(branch_names)
        return nil unless branch_names and not branch_names == [HeadBranchName]
        (branch_names.include?(HeadBranchName) ? ['CURRENT'] : []) + branch_names.reject { |b| b == HeadBranchName }.sort
      end

      #
      # method will not return 'v' in version name, when used for comparison
      def branch_names_to_versions_stripped(branch_names)
        versions = branch_names_to_versions(branch_names)
        versions ? versions.collect { |v| v.gsub(/^v/, '') } : nil
      end

      private :branch_names_to_versions

      def version_to_branch_name(version = nil)
        self.class.version_to_branch_name(version)
      end
      def self.version_to_branch_name(version = nil)
        Log.info_pp(['#TODO: ModuleBranch::Location: deprecating: version_to_branch_name', caller[0..4]])
        if version.nil? || version == HeadBranchName
          HeadBranchName
        else
          "v#{version}"
        end
      end
      HeadBranchName = 'master'

      def default_remote_repo_base
        self.class.default_remote_repo_base
      end
      def self.default_remote_repo_base
        RepoRemote.repo_base
      end

      # TODO: deprecate when remove all references to these
      def default_remote_repo
        self.class.default_remote_repo_base
      end
      def self.default_remote_repo
        default_remote_repo_base
      end

      def self.default_user_namespace
        # CurrentSession.new.get_user_object.get_namespace
        # we don't want username as default namespace, we will use tenant unique name instead
        # ::DTK::Common::Aux.running_process_user
        Namespace.default_namespace_name
      end

      # TODO: this needs to be cleaned up
      def self.default_namespace
        self.default_user_namespace
      end

      DefaultsNamespace = 'r8' #TODO: have this obtained from config file

      # [Haris] We are not using r8 here since we will use tenant id, e.g. "dtk9" as default
      # DefaultsNamespace = self.default_user_namespace #TODO: have this obtained from config file

      # example:
      # returns namespace, name, version (optional)
      def self.split_qualified_name(qualified_name, opts = {})
        fail ErrorUsage.new('Please provide module name to publish') if qualified_name.nil? || qualified_name.empty?
        namespace = opts[:namespace] || default_namespace

        split = qualified_name.split('/')
        case split.size
         when 1 then [namespace, qualified_name]
         when 2, 3 then split
         else
          qualified_name = 'NOT PROVIDED' if qualified_name.nil? || qualified_name.empty?
          fail ErrorUsage.new("Module remote name (#{qualified_name}) ill-formed. Must be of form 'name', 'namespace/name' or 'name/namespace/version'")
        end
      end

      private

      attr_reader :client

      def type_for_remote_module(module_type)
        module_type.to_s.gsub(/_module$/, '')
      end

      def is_empty?(string_value)
        return true if string_value.nil?
        string_value.empty? ? true : false
      end

      def dtk_instance_rsa_pub_key
        @dtk_instance_rsa_pub_key ||= Common::Aux.get_ssh_rsa_pub_key
      end

      def current_tenant_username
        "#{dtk_instance_prefix}-dtk-instance"
      end

      def dtk_instance_prefix
        ::R8::Config[:repo][:remote][:tenant_name] || ::DTK::Common::Aux.running_process_user
      end

      def dtk_instance_remote_repo_key_name
        'dtk-instance-key'
      end

      def get_end_user_remote_repo_username(mh, ssh_rsa_pub_key)
        RepoUser.match_by_ssh_rsa_pub_key!(mh, ssh_rsa_pub_key).owner.username
      end
    end
  end
end
