r8_require("#{::R8::Config[:sys_root_path]}/repo_manager_client/lib/repo_manager_client")
module DTK
 class RepoRemote < Repo
    class << self
      def list(repo_mh)
        remote_repo_names = client.list_repos()
        #TODO: might also indicate if any of these are synced with remote repo
        remote_repo_names.map{|name|{:display_name => name}}
      end

      def authorize_dtk_instance(remote_repo_name)
        username = dtk_instance_username()
        rsa_pub_key = dtk_instance_rsa_pub_key()
        access_rights = "RW+"
        client.add_user(username,rsa_pub_key,:noop_if_exists => true)
        client.add_user_to_repo(username,remote_repo_name,access_rights)
        remote_repo_name
      end

     private
      def client()
        @client ||= RepoManagerClient.new(::R8::Config[:repo][:remote][:rest_base_url])
      end

      def dtk_instance_rsa_pub_key()
        @dtk_instance_rsa_pub_key ||= AuxCommon.get_ssh_rsa_pub_key()
      end
      def dtk_instance_username()
        @dtk_instance_username ||= "dtk-#{AuxCommon.get_macaddress().gsub(/:/,'-')}"
      end
    end
  end
end

