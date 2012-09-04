r8_require("#{::R8::Config[:sys_root_path]}/repo_manager_client/lib/repo_manager_client")
module DTK
 class Repo
    class Remote
      def initialize(rest_base_url=default_rest_base_url())
        @client = RepoManagerClient.new(rest_base_url)
      end

      #create (empty) remote module
      def create_module(name,type)
        username = dtk_instance_username()
        rsa_pub_key = dtk_instance_rsa_pub_key()

        client.create_user(username,rsa_pub_key,:update_if_exists => true)

        params = {
          :username => username,
          :name => name,
          :access_rights => "RW+", 
          :type => type_for_remote_module(type),
          :namespace => self.class.default_namespace(),
          :noop_if_exists => true
        } 
        response_data = client.create_module(params)
        Aux.convert_keys_to_symbols(response_data)
      end

      def get_module_info(name,type,namespace=nil)
        params = {
          :name => name,
          :type => type_for_remote_module(type),
          :namespace => namespace || self.class.default_namespace()
        } 
        response_data = client.get_module_info(params)
        Aux.convert_keys_to_symbols(response_data)
      end

      def list_module_qualified_names(type=nil)
        filter = type && {:type => type_for_remote_module(type)}
        remote_modules = client.list_modules(filter)
        remote_modules.map do |r|
          el = ((type.nil? and r["type"]) ? {:type => r[:type]} : {}) 
          namespace = r["namespace"] && "#{r["namespace"]}/"
          el.merge(:name => "#{namespace}#{r["name"]}")
        end
      end

      def authorize_dtk_instance(remote_repo_name,type)
        username = dtk_instance_username()
        rsa_pub_key = dtk_instance_rsa_pub_key()
        access_rights = "RW+"
        client.create_user(username,rsa_pub_key,:update_if_exists => true)
        grant_user_rights_params = {
          :name => remote_repo_name,
          :namespace => DefaultsNamespace,
          :type => type_for_remote_module(type),
          :username => username,
          :accesss_rights => access_rights
        }
        client.grant_user_access_to_module(grant_user_rights_params)
        remote_repo_name
      end

      def repo_url_ssh_access(remote_repo_name)
        client.repo_url_ssh_access(remote_repo_name,::R8::Config[:repo][:remote][:git_user])
      end

      def self.default_namespace()
        DefaultsNamespace
      end
      DefaultsNamespace = "r8" #TODO: have this obtained from config file

      #returns name, namespace
      def self.split_qualified_name(qualified_name)
        name,namespace = qualified_name.split("/")
        [name,namespace||default_namespace()]
      end

     private
      attr_reader :client

      def type_for_remote_module(module_type)
        module_type.to_s.gsub(/_module$/,"")
      end

      def default_rest_base_url()
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

