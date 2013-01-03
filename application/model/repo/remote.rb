r8_require("#{::R8::Config[:sys_root_path]}/repo_manager_client/lib/repo_manager_client")
module DTK
 class Repo
    class Remote
      class ModuleRepoInfo < Hash
        #has keys
        #  :repo_url
        #  :remote_repo 
        #  :remote_branch
        #  :module_name
        def initialize(remote,module_name,remote_repo=nil,version=nil)
          super()
          remote_repo ||= remote.default_remote_repo()
          hash = {
            :module_name => module_name,
            :remote_repo => remote_repo.to_s,
            :repo_url => remote.rest_base_url(remote_repo),
            :remote_branch => remote.version_to_branch_name(version)
          }
          replace(hash)
        end
      end

      r8_nested_require('remote','auth')
      include AuthMixin

      def initialize(remote_repo=nil)
        rest_base_url = rest_base_url(remote_repo)
        @client = RepoManagerClient.new(rest_base_url)
      end

      #create (empty) remote module
      def create_module(name,type)
        username = dtk_instance_remote_repo_username()
        rsa_pub_key = dtk_instance_rsa_pub_key()

        client.create_user(username,rsa_pub_key,:update_if_exists => true)
        namespace = self.class.default_namespace()
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

      def delete_module(name,type)
        namespace = self.class.default_namespace()
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
        response_data = client.get_module_info(client_params)
        ret = Aux.convert_keys_to_symbols(response_data)
        unless ret 
          raise ErrorUsage.new("Remote module (#{qualified_module_name(remote_params)}) does not exist")
        end
        if remote_params[:version]
          versions = branch_names_to_versions(ret[:branches])
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
      private :branch_names_to_versions

      def version_to_branch_name(version)
        self.class.version_to_branch_name(version)
      end
      def self.version_to_branch_name(version)
        version ? version : HeadBranchName
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
      def self.default_namespace()
        DefaultsNamespace
      end
      DefaultsNamespace = "r8" #TODO: have this obtained from config file

      #returns namespace, name, version (optional)
      def self.split_qualified_name(qualified_name)
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
        @dtk_instance_remote_repo_username ||= Common::Aux.dtk_instance_repo_username()
      end
      def get_end_user_remote_repo_username(mh,ssh_rsa_pub_key)
        "#{dtk_instance_remote_repo_username()}--#{RepoUser.match_by_ssh_rsa_pub_key(mh,ssh_rsa_pub_key)[:username]}"
      end
 
    end
  end
end

