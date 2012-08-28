r8_require("#{::R8::Config[:sys_root_path]}/repo_manager_client/lib/repo_manager_client")
module DTK
 class Repo
    class Remote
      def initialize(rest_base_url=default_rest_base_url())
        @client = RepoManagerClient.new(rest_base_url)
      end

      def list_repo_names(type=nil)
        remote_repos = client.list_repos()
        ret = Array.new
        remote_repos.map do |repo|
          repo_type = repo["type"]
          if repo_type and type
            if type == :component_module and not repo_type.is_component_module?()
              next
            elsif type == :service_module and not repo_type.is_service_module?()
              next
            end
          end
          el = {:repo_name => repo["repo_name"]}
          el[:type] = repo_type if repo_type and not type
          ret << el
        end
        ret
      end

      #create remote repo
      def create_repo(repo_name)
        username = dtk_instance_username()
        rsa_pub_key = dtk_instance_rsa_pub_key()
        access_rights = "RW+"
        client.add_user(username,rsa_pub_key,:noop_if_exists => true)
        client.create_repo(username,repo_name,access_rights)
        repo_name
      end

      def authorize_dtk_instance(remote_repo_name)
        username = dtk_instance_username()
        rsa_pub_key = dtk_instance_rsa_pub_key()
        access_rights = "RW+"
        client.add_user(username,rsa_pub_key,:noop_if_exists => true)
        client.set_user_rights_in_repo(username,remote_repo_name,access_rights)
        remote_repo_name
      end

      def repo_url_ssh_access(remote_repo_name)
        client.repo_url_ssh_access(remote_repo_name,::R8::Config[:repo][:remote][:git_user])
      end

     private
      attr_reader :client

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

