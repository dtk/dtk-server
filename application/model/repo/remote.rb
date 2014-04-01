r8_require("#{::R8::Config[:sys_root_path]}/repo_manager_client/lib/repo_manager_client")
#TODO: cleanup confusing variables names to distinguis between
# - the actual remote's repo name
# - the remote base (e.g., dtkn)
# - the local clone's remote 
#
# started some of this renaming
module DTK
  class Repo
    module RemoteMixin
      def linked_remote?()
        get_field?(:remote_repo_name)
      end

      #TODO: ModuleBranch::Location: signature should be
      #initial_sync_with_remote_repo(remote_location) maybe with local_branch if not in self
      def initial_sync_with_remote_repo(remote_ref,local_branch,version=nil)
        unless R8::Config[:repo][:workspace][:use_local_clones]
          raise Error.new("Not implemented yet: initial_sync_with_remote_repo w/o local clones")
        end
        update_object!(:repo_name,:remote_repo_name)
        unless get_field?(:remote_repo_name)
          raise ErrorUsage.new("Cannot synchronize with remote repo if local repo not linked")
        end
        remote_url = repo_url_ssh_access()
        remote_ref ||= get_remote_ref()
        remote_branch = Remote.version_to_branch_name(version)
        commit_sha = RepoManager.initial_sync_with_remote_repo(local_branch,get_field?(:repo_name),remote_ref,remote_url,remote_branch)
        
        commit_sha
      end

      def ret_remote_merge_relationship(remote_ref,local_branch,version,opts={})
        remote_ref ||= get_remote_ref()
        remote_branch = Remote.version_to_branch_name(version)
        RepoManager.ret_remote_merge_relationship(get_field?(:repo_name),local_branch,remote_ref,opts.merge(:remote_branch => remote_branch))
      end

      def ret_loaded_and_remote_diffs(module_branch,opts={})
        version = opts[:version]
        remote_url = repo_url_ssh_access()
        remote_ref = opts[:remote_name]||get_remote_ref()
        remote_branch = Remote.version_to_branch_name(version)
        RepoManager.get_loaded_and_remote_diffs(remote_ref, get_field?(:repo_name), module_branch, remote_url, remote_branch)
      end
      
      def push_to_remote(branch,remote_repo_name,version=nil)
        unless remote_repo_name
          raise ErrorUsage.new("Cannot push to remote repo if local repo not linked")
        end
        remote_ref = get_remote_ref()
        remote_branch = Remote.version_to_branch_name(version)
        RepoManager.push_to_remote_repo(get_field?(:repo_name),branch,remote_ref,remote_branch)
      end

      def remote_exists?(remote_repo_name)
        remote_url = repo_url_ssh_access(remote_repo_name)
        RepoManager.git_remote_exists?(remote_url)
      end

      def link_to_remote(branch,remote_repo_name)
        remote_url = repo_url_ssh_access(remote_repo_name)
        remote_ref = get_remote_ref()
        RepoManager.link_to_remote_repo(get_field?(:repo_name),branch,remote_ref,remote_url)
        remote_repo_name
      end
      
      def unlink_remote(remote_ref)
        remote_ref ||= get_remote_ref()
        RepoManager.unlink_remote(get_field?(:repo_name),remote_ref)
        
        update(:remote_repo_name => nil, :remote_repo_namespace => nil)
      end

      def repo_url_ssh_access(remote_repo_name=nil)
        remote_repo_name ||= get_field?(:remote_repo_name)
        RepoManagerClient.repo_url_ssh_access(remote_repo_name)
      end

      def get_remote_ref(opts={})
        remote_repo_base = opts[:remote_repo_base]||Remote.default_remote_repo_base()
        if remote_repo_namespace = get_field?(:remote_repo_namespace)
          "#{remote_repo_base}--#{remote_repo_namespace}"
        else
          Log.error("Not expecting :remote_repo_namespace to be nil")
          remote_repo_base
        end
      end
    end

    class Remote

      CREATE_MODULE_PERMISSIONS = { :user => 'RWDP', :user_group => 'RWDP', :other => 'R'}
      r8_nested_require('remote','auth')
      include AuthMixin

      def get_remote_module_components(module_name, type, version, namespace)
        params = {
          :name => module_name,
          :version => version,
          :namespace => namespace,
          :type => type,
          :do_not_raise => true
        }
        @client.get_components_info(params)
      end

      def initialize(remote_repo_base=nil)
        @remote_repo_base = remote_repo_base && remote_repo_base.to_sym 
        @client = RepoManagerClient.new(repo_url = rest_base_url(@remote_repo_base))
        Log.debug "Using repo manager: '#{repo_url}'"
      end

      def create_client_user(client_rsa_pub_key)
        client.create_client_user(client_rsa_pub_key)
      end

      def remove_client_user(username)
        client.remove_client_user(username)
      end

      def create_module(name, type, namespace = nil, client_rsa_pub_key = nil)
        username = dtk_instance_remote_repo_username()
        rsa_pub_key = dtk_instance_rsa_pub_key()

        client.create_user(username, rsa_pub_key, { :update_if_exists => true }, client_rsa_pub_key)
        #namespace = self.class.default_namespace()
        namespace ||= CurrentSession.new.get_user_object().get_namespace()

        params = {
          :username => username,
          :name => name,
          :permission_hash => CREATE_MODULE_PERMISSIONS,
          :type => type_for_remote_module(type),
          :namespace => namespace,
          :noop_if_exists => true
        } 
        response_data = client.create_module(params, client_rsa_pub_key)

        {:remote_repo_namespace => namespace}.merge(Aux.convert_keys_to_symbols(response_data))
      end

      # TODO: [Haris] We should refactor this so that arguments are passed in more logical
      # order, (name, namespace, type) for now we can live with it
      def delete_module(name, type, namespace=nil, client_rsa_pub_key = nil)
        # if namespace omitted we will use default one
        namespace ||= self.class.default_namespace()
        params = {
          :username => dtk_instance_remote_repo_username(),
          :name => name,
          :namespace => namespace,
          :type => type_for_remote_module(type)
        }
        
        client.delete_module(params, client_rsa_pub_key)
      end

      class Info < Hash
      end 
      def get_remote_module_info(branch_obj,remote_params)
        unless repo = branch_obj[:repo]
          raise Error.new("Expected the :repo field to be non null")
        end
        remote_ref = repo.get_remote_ref(:remote_repo_base => @remote_repo_base) 
        ret = Info.new().merge(
          :module_name => remote_params[:module_name],
          #TODO: will change this to :remote_ref when upstream uses this                               
          :remote_repo => remote_ref,
          :remote_repo_url => repo.repo_url_ssh_access(remote_params[:remote_repo_name]),
          :remote_branch => version_to_branch_name(remote_params[:version]),
          :workspace_branch => branch_obj.get_field?(:branch)
        )
        ret.merge!(:version => remote_params[:version]) if remote_params[:version]        
        ret
      end
      # unify these two or chose better names to show how different
      #returns  module info it exists
      def exists?(remote)
        client_params = {
          :name => remote.module_name,
          :type => type_for_remote_module(remote.module_type),
          :namespace => remote.namespace || self.class.default_namespace()
        } 

        ret = nil
        begin
          response_data = client.get_module_info(client_params)
          ret = Aux.convert_keys_to_symbols(response_data)
        rescue ErrorUsage => e
          # Amar: To handle DTK-819: Returning friendly error message to CLI below if 'ret' is nil
        end
        unless ret 
          raise ErrorUsage.new("Remote module (#{remote.pp_module_name(:include_namespace=>true)}) does not exist")
        end
        if remote.version
          raise Error.new("Not implementing versions")
          versions = branch_names_to_versions_stripped(ret[:branches])
          unless versions and versions.include?(remote.version)
            raise ErrorUsage.new("Remote module (#{remote.pp_module_name(:include_namespace=>true)}}) does not have version (#{remote.version||"CURRENT"})")
          end
        end
        ret
      end

      #TODO: ModuleBranch::Location: remove once put this in place for module/mixin/delete
      def get_module_info(remote_params)
        client_params = {
          :name => remote_params[:module_name],
          :type => type_for_remote_module(remote_params[:module_type]),
          :rsa_pub_key => remote_params[:rsa_pub_key],
          :namespace => remote_params[:module_namespace] || self.class.default_namespace()
        } 

        ret = nil
        begin
          response_data = client.get_module_info(client_params)
          ret = Aux.convert_keys_to_symbols(response_data)
        rescue ErrorUsage => e
          # Amar: To handle DTK-819: Returning friendly error message to CLI below if 'ret' is nil
        end
        unless ret 
          raise ErrorUsage.new("Remote component/service (#{qualified_module_name(remote_params)}) does not exist")
        end
        if remote_params[:version]
          versions = branch_names_to_versions_stripped(ret[:branches])
          unless versions and versions.include?(remote_params[:version])
            raise ErrorUsage.new("Remote module (#{qualified_module_name(remote_params)}) does not have version (#{remote_params[:version]||"CURRENT"})")
          end
        end
        ret
      end
      def qualified_module_name(remote_params)
        "#{remote_params[:module_namespace]}/#{remote_params[:module_name]}"
      end
      private :qualified_module_name

      def list_module_info(type=nil, rsa_pub_key = nil)
        new_repo = R8::Config[:repo][:remote][:new_client]
        filter = type && {:type => type_for_remote_module(type)}
        remote_modules = client.list_modules(filter, rsa_pub_key)
        
        remote_modules.map do |r|
          el = ((type.nil? and r["type"]) ? {:type => r[:type]} : {}) 
          # TODO: remove first way of getting namespace when transfer to new repo
          namespace = r["namespace"] && "#{r["namespace"]}/"
          namespace = r["namespace"]["name"] && "#{r["namespace"]["name"]}/" if new_repo
          qualified_name = "#{namespace}#{r["name"]}"
          last_updated = r['updated_at'] && Time.parse(r['updated_at']).strftime("%Y/%m/%d %H:%M:%S")
          el.merge!(:qualified_name => qualified_name, :last_updated => last_updated)
          if versions = branch_names_to_versions(r["branches"])
            el.merge!(:versions => versions)
          end
          el
        end
      end

      def branch_names_to_versions(branch_names)
        return nil unless branch_names and not branch_names == [HeadBranchName]
        (branch_names.include?(HeadBranchName) ? ["CURRENT"] : []) + branch_names.reject{|b|b == HeadBranchName}.sort
      end

      #
      # method will not return 'v' in version name, when used for comparison
      def branch_names_to_versions_stripped(branch_names)
        versions = branch_names_to_versions(branch_names)
        versions ? versions.collect { |v| v.gsub(/^v/,'') } : nil
      end

      private :branch_names_to_versions

      def version_to_branch_name(version=nil)
        self.class.version_to_branch_name(version)
      end
      def self.version_to_branch_name(version=nil)
        if version.nil? or version == HeadBranchName
          HeadBranchName
        else
          "v#{version}" 
        end
      end
      HeadBranchName = "master"
      
      def default_remote_repo_base()
        self.class.default_remote_repo_base()
      end
      def self.default_remote_repo_base()
        :dtknet #TODO: have this obtained from config file
      end

      #TODO: deprecate when remove all references to these
      def default_remote_repo()
        self.class.default_remote_repo_base()
      end
      def self.default_remote_repo()
        default_remote_repo_base()
      end

      def self.default_user_namespace()
        # CurrentSession.new.get_user_object().get_namespace()
        # we don't want username as default namespace, we will use tenant unique name instead
        ::DTK::Common::Aux.running_process_user()
      end

      #TODO: this needs to be cleaned up
      def self.default_namespace()
        self.default_user_namespace()
      end
      
      DefaultsNamespace = "r8" #TODO: have this obtained from config file

      # [Haris] We are not using r8 here since we will use tenant id, e.g. "dtk9" as default
      # DefaultsNamespace = self.default_user_namespace() #TODO: have this obtained from config file

      # example: 
      #returns namespace, name, version (optional)
      def self.split_qualified_name(qualified_name)
        raise ErrorUsage.new("Please provide module name to publish") unless qualified_name

        split = qualified_name.split("/")
        case split.size
         when 1 then [default_namespace(),qualified_name]
         when 2,3 then split
        else
          raise ErrorUsage.new("Module remote name (#{qualified_name}) ill-formed. Must be of form 'name', 'namespace/name' or 'name/namespace/version'")
        end
      end

      def rest_base_url(remote_repo=nil)
        unless remote_repo.nil? or remote_repo == default_remote_repo()
          raise Error.new("MOD_RESTRUCT:  need to put in logic to treat non default repo_name")
        end
        #TODO: change config so that it has ability to have multiple repos and use form like
        #remote = ::R8::Config[:repo][:remote][remote_repo]
        remote = ::R8::Config[:repo][:remote]
        is_ssl = remote[:rest_port].to_i == 443

        "http#{is_ssl ? 's' : ''}://#{remote[:host]}:#{remote[:rest_port].to_s}"
      end

     private
      attr_reader :client

      def type_for_remote_module(module_type)
        module_type.to_s.gsub(/_module$/,"")
      end

      def dtk_instance_rsa_pub_key()
        @dtk_instance_rsa_pub_key ||= Common::Aux.get_ssh_rsa_pub_key()
      end
      def dtk_instance_remote_repo_username()
        "dtk-instance"
      end
      def get_end_user_remote_repo_username(mh,ssh_rsa_pub_key)
        RepoUser.match_by_ssh_rsa_pub_key(mh,ssh_rsa_pub_key)[:username]
      end
 
    end
  end
end

