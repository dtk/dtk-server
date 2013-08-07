r8_require("#{::R8::Config[:sys_root_path]}/repo_manager_client/lib/repo_manager_client")
r8_require("#{::R8::Config[:sys_root_path]}/repo_manager_client/lib/repo_manager_client")
module DTK
  class Repo
    module RemoteMixin
      def linked_remote?(remote_repo=nil) 
        unless remote_repo.nil? or remote_repo == Repo::Remote.default_remote_repo()
          raise Error.new("Not implemented yet for remote's other than default")
        end
        update_object!(:remote_repo_name)[:remote_repo_name]
      end

      def initial_sync_with_remote_repo(remote_repo,local_branch,version=nil)
        unless R8::Config[:repo][:workspace][:use_local_clones]
          raise Error.new("Not implemented yet: synchronize_with_remote_repo w/o local clones")
        end
        update_object!(:repo_name,:remote_repo_name)
        unless self[:remote_repo_name]
          raise ErrorUsage.new("Cannot synchronize with remote repo if local repo not linked")
        end
        remote_url = Remote.new(remote_repo).repo_url_ssh_access(self[:remote_repo_name])
        remote_name = remote_name_for_push_pull(remote_repo)
        remote_branch = Remote.version_to_branch_name(version)
        commit_sha = RepoManager.initial_sync_with_remote_repo(local_branch,self[:repo_name],remote_name,remote_url,remote_branch)
        
        commit_sha
      end

      #MOD_RESTRUCT: TODO: may deprecate
      def synchronize_with_remote_repo(remote_repo,local_branch,version=nil)
        unless R8::Config[:repo][:workspace][:use_local_clones]
          raise Error.new("Not implemented yet: synchronize_with_remote_repo w/o local clones")
        end
        update_object!(:repo_name,:remote_repo_name)
        unless self[:remote_repo_name]
          raise ErrorUsage.new("Cannot synchronize with remote repo if local repo not linked")
        end
        remote_url = Remote.new(remote_repo).repo_url_ssh_access(self[:remote_repo_name])
        remote_name = remote_name_for_push_pull(remote_repo)
        remote_branch = Remote.version_to_branch_name(version)
        RepoManager.synchronize_with_remote_repo(self[:repo_name],local_branch,remote_name,remote_url,:remote_branch => remote_branch)
      end
      
      def ret_remote_merge_relationship(remote_repo,local_branch,version,opts={})
        update_object!(:repo_name)
        remote_name = remote_name_for_push_pull(remote_repo)
        remote_branch = Remote.version_to_branch_name(version)
        RepoManager.ret_remote_merge_relationship(self[:repo_name],local_branch,remote_name,opts.merge(:remote_branch => remote_branch))
      end

      def ret_loaded_and_remote_diffs(remote_r, module_branch, version=nil)
        remote_url = Remote.new(remote_r).repo_url_ssh_access(self[:remote_repo_name])
        remote_name = remote_name_for_push_pull(remote_r)
        remote_branch = Remote.version_to_branch_name(version)
        return RepoManager.get_loaded_and_remote_diffs(remote_r, self[:repo_name], module_branch, remote_url, remote_name, remote_branch)
      end
      
      def push_to_remote(branch,remote_repo_name,version=nil)
        unless remote_repo_name
          raise ErrorUsage.new("Cannot push to remote repo if local repo not linked")
        end
        update_object!(:repo_name)
        remote_name = remote_name_for_push_pull()
        remote_branch = Remote.version_to_branch_name(version)
        RepoManager.push_to_remote_repo(self[:repo_name],branch,remote_name,remote_branch)
      end

      def remote_exists?(branch,remote_repo_name)
        update_object!(:repo_name)
        remote_url = Remote.new.repo_url_ssh_access(remote_repo_name)
        RepoManager.git_remote_exists?(remote_url)
      end

      def link_to_remote(branch,remote_repo_name)
        update_object!(:repo_name)
        remote_url = Remote.new.repo_url_ssh_access(remote_repo_name)
        remote_name = remote_name_for_push_pull()
        RepoManager.link_to_remote_repo(self[:repo_name],branch,remote_name,remote_url)
        remote_repo_name
      end
      
      def unlink_remote(remote_repo)
        update_object!(:repo_name)
        remote_name = remote_name_for_push_pull(remote_repo)
        RepoManager.unlink_remote(self[:repo_name],remote_name)
        
        update(:remote_repo_name => nil, :remote_repo_namespace => nil)
      end
      
     private    
      def remote_name_for_push_pull(remote_name=nil)
        remote_name||"remote"
      end
    end

    class Remote
      class RemoteModuleRepoInfo < Hash
        #has keys
        #  :remote_repo_url
        #  :remote_repo 
        #  :remote_branch
        #  :module_name
        #  :version
        def initialize(parent,branch_obj,remote_params)
          super()
          remote_repo = @remote_repo||parent.default_remote_repo()
          hash = {
            :module_name => remote_params[:module_name],
            :remote_repo => remote_repo.to_s,
            :remote_repo_url => parent.repo_url_ssh_access(remote_params[:remote_repo_name]),
            :remote_branch => parent.version_to_branch_name(remote_params[:version]),
            :workspace_branch => branch_obj.get_field?(:branch)
          }
          hash.merge!(:version => remote_params[:version]) if remote_params[:version]
          replace(hash)
        end
      end

      r8_nested_require('remote','auth')
      include AuthMixin

      def get_remote_module_info(branch_obj,remote_params)
        RemoteModuleRepoInfo.new(self,branch_obj,remote_params)
      end

      def get_remote_module_components(module_name, type, version, namespace)
        params = {
          :name => module_name,
          :version => version,
          :namespace => namespace,
          :type => type
        }
        @client.get_components_info(params)
      end

      def initialize(remote_repo=nil)
        @remote_repo = remote_repo
        @client = RepoManagerClient.new(repo_url = rest_base_url(remote_repo))
        Log.debug "Using repo manager: '#{repo_url}'"
      end

      def create_module(name, type, namespace = nil)
        username = dtk_instance_remote_repo_username()
        rsa_pub_key = dtk_instance_rsa_pub_key()

        client.create_user(username,rsa_pub_key,:update_if_exists => true)
        #namespace = self.class.default_namespace()
        namespace ||= CurrentSession.new.get_user_object().get_namespace()

        params = {
          :username => username,
          :name => name,
          :access_rights => "RW+",
          :type => type_for_remote_module(type),
          :namespace => namespace,
          :noop_if_exists => true
        } 
        response_data = client.create_module(params)

        {:remote_repo_namespace => namespace}.merge(Aux.convert_keys_to_symbols(response_data))
      end

      # TODO: [Haris] We should refactor this so that arguments are passed in more logical
      # order, (name, namespace, type) for now we can live with it
      def delete_module(name,type, namespace=nil)
        # if namespace omitted we will use default one
        namespace ||= self.class.default_namespace()
        params = {
          :name => name,
          :namespace => namespace,
          :type => type_for_remote_module(type)
        }
        client.delete_module(params)
      end

      def get_module_info(remote_params)
        client_params = {
          :name => remote_params[:module_name],
          :type => type_for_remote_module(remote_params[:module_type]),
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

      def list_module_info(type=nil)
        filter = type && {:type => type_for_remote_module(type)}
        remote_modules = client.list_modules(filter)

        remote_modules.map do |r|
          el = ((type.nil? and r["type"]) ? {:type => r[:type]} : {}) 
          namespace = r["namespace"] && "#{r["namespace"]}/"
          qualified_name = "#{namespace}#{r["name"]}"
          el.merge!(:qualified_name => qualified_name)
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

      def version_to_branch_name(version)
        self.class.version_to_branch_name(version)
      end
      def self.version_to_branch_name(version)
        version ? "v#{version}" : HeadBranchName
      end
      HeadBranchName = "master"
      
      def repo_url_ssh_access(remote_repo_name)
        client.repo_url_ssh_access(remote_repo_name,::R8::Config[:repo][:remote][:git_user])
      end

      def default_remote_repo()
        self.class.default_remote_repo()
      end
      def self.default_remote_repo()
        :r8_network #TODO: have this obtained from config file
      end

      def self.default_user_namespace()
        CurrentSession.new.get_user_object().get_namespace()
      end

      def self.default_namespace()
        self.default_user_namespace()
      end
      DefaultsNamespace = "r8" #TODO: have this obtained from config file

      # [Haris] We are not using r8 here since we will use tenant id, e.g. "dtk9" as default
      # DefaultsNamespace = self.default_user_namespace() #TODO: have this obtained from config file

      # example: 
      #returns namespace, name, version (optional)
      def self.split_qualified_name(qualified_name)
        raise ErrorUsage.new("Please provide module name to export") unless qualified_name

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
        "http://#{remote[:host]}:#{remote[:rest_port].to_s}"
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

