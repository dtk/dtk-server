r8_require("#{::R8::Config[:sys_root_path]}/repo_manager_client/lib/repo_manager_client")
module DTK
  class Repo
    #TODO: may have better class name; this is really a remote repo server handler
    class Remote
      CREATE_MODULE_PERMISSIONS = { :user => 'RWDP', :user_group => 'RWDP', :other => 'R'}
      r8_nested_require('remote','auth')
      include AuthMixin

      def initialize(remote_or_repo_base=nil)
        arg = remote_or_repo_base #for succinctness
        if ModuleBranch::Location::Remote.includes?(arg)
          @remote = arg
          @project = @remote.project
          @remote_repo_base = @remote.remote_repo_base
        elsif arg
          @remote_repo_base = arg.to_sym
        end

        repo_url = rest_base_url(@remote_repo_base)
        @client = RepoManagerClient.new(repo_url)
        Log.debug "Using repo manager: '#{repo_url}'"
      end

      def create_client_user(client_rsa_pub_key)
        client.create_client_user(client_rsa_pub_key)
      end

      def remove_client_user(username)
        client.remove_client_user(username)
      end

      def create_remote_module(client_rsa_pub_key)
        username = dtk_instance_remote_repo_username()
        rsa_pub_key = dtk_instance_rsa_pub_key()
        client.create_user(username, rsa_pub_key, { :update_if_exists => true }, client_rsa_pub_key)
        
        unless namespace = remote.namespace 
          namespace = CurrentSession.new.get_user_object().get_namespace()
          Log.error("Unexpected that naemspace was null and used CurrentSession.new.get_user_object().get_namespace(): #{namespace}}")
        end
        params = {
          :username => username,
          :name => remote.module_name(),
          :permission_hash => CREATE_MODULE_PERMISSIONS,
          :type => type_for_remote_module(remote.module_type),
          :namespace => namespace,
          :noop_if_exists => true
        } 
        response_data = client.create_module(params, client_rsa_pub_key)

        {:remote_repo_namespace => namespace}.merge(Aux.convert_keys_to_symbols(response_data))
      end

      def delete_remote_module(client_rsa_pub_key)
        raise_error_if_module_is_not_accessible(client_rsa_pub_key)
        params = {
          :username => dtk_instance_remote_repo_username(),
          :name => remote.module_name,
          :namespace => remote.namespace,
          :type => type_for_remote_module(remote.module_type)
        }
        client.delete_module(params, client_rsa_pub_key)
      end

      def raise_error_if_module_is_not_accessible(client_rsa_pub_key)
        get_remote_module_info?(client_rsa_pub_key,:raise_error => true)
      end
      private :raise_error_if_module_is_not_accessible

      def get_remote_module_info?(client_rsa_pub_key,opts={})
        client_params = {
          :name => remote.module_name,
          :type => type_for_remote_module(remote.module_type),
          :namespace => remote.namespace,
          :rsa_pub_key => client_rsa_pub_key
        } 
        ret = nil
        begin
          response_data = client.get_module_info(client_params)
          ret = Aux.convert_keys_to_symbols(response_data)
        rescue 
          if opts[:raise_error]
            raise ErrorUsage.new("Remote module (#{remote.pp_module_name(:include_namespace=>true)}) does not exists or is not accessible")
          else
            return nil
          end
        end
        ret.merge!(:remote_repo_url => RepoManagerClient.repo_url_ssh_access(ret[:git_repo_name]))

        if remote.version
          #TODO: ModuleBranch::Location: 
          raise Error.new("Not versions not implemented")
          versions = branch_names_to_versions_stripped(ret[:branches])
          unless versions and versions.include?(remote.version)
            raise ErrorUsage.new("Remote module (#{remote.pp_module_name(:include_namespace=>true)}}) does not have version (#{remote.version||"CURRENT"})")
          end
        end
        ret
      end

      def get_remote_module_components()
        params = {
          :name => remote.module_name,
          :version => remote.version,
          :namespace => remote.namespace,
          :type => remote.module_type,
          :do_not_raise => true
        }
        @client.get_components_info(params)
      end


      def remote()
        unless @remote
          raise Error.new("Should not be called if @remote is nill")
        end
        @remote
      end
      private :remote

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
        Log.error("#TODO: ModuleBranch::Location: deprecating: version_to_branch_name")
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
        RepoRemote.repo_base()
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

