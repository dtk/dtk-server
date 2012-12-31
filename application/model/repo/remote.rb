r8_require("#{::R8::Config[:sys_root_path]}/repo_manager_client/lib/repo_manager_client")
module DTK
 class Repo
    class Remote
      def initialize(remote_repo=nil)
        rest_base_url = rest_base_url(remote_repo)
        @client = RepoManagerClient.new(rest_base_url)
      end

      #create (empty) remote module
      def create_module(name,type)
        username = dtk_instance_username()
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
        (branches.include?(HeadBranchName) ? ["CURRENT"] : []) + branches.reject{|b|b == HeadBranchName}.sort
      end
      private :branch_names_to_versions
      def self.version_to_branch_name(version)
        version ? version : HeadBranchName
      end
      HeadBranchName = "master"
      

      def authorize_dtk_instance(module_name,type)
        username = dtk_instance_username()
        rsa_pub_key = dtk_instance_rsa_pub_key()
        access_rights = "RW+"
        client.create_user(username,rsa_pub_key,:update_if_exists => true)
        grant_user_rights_params = {
          :name => module_name,
          :namespace => DefaultsNamespace,
          :type => type_for_remote_module(type),
          :username => username,
          :access_rights => access_rights
        }
        client.grant_user_access_to_module(grant_user_rights_params)
        module_name
      end

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

     private
      attr_reader :client

      def type_for_remote_module(module_type)
        module_type.to_s.gsub(/_module$/,"")
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

      def dtk_instance_rsa_pub_key()
        @dtk_instance_rsa_pub_key ||= Common::Aux.get_ssh_rsa_pub_key()
      end
      def dtk_instance_username()
        @dtk_instance_username ||= Common::Aux.dtk_instance_repo_username()
      end
    end
  end
end

