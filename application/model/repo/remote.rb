r8_require("#{::R8::Config[:sys_root_path]}/repo_manager_client/lib/repo_manager_client")
module DTK
 class RepoRemote < Repo
    class << self
      def list_remote(repo_mh)
        remote_repo_names = client.list_repos()
        #TODO: might also indicate if any of these are synced with remote repo
        remote_repo_names.map{|name|{:display_name => name}}
      end

      def authorize_dtk_instance(remote_repo_name)
        username = dtk_instance_username()
        access_rights = "RW+"
        client.add_user_to_repo(username,remote_repo_name,access_rights)
      end

     private
      def client()
        @client ||= RepoManagerClient.new(::R8::Config[:repo][:remote][:rest_base_url])
      end

      def dtk_instance_public_key()
        return dtk_instance_public_key if dtk_instance_public_key
        require 'facter' #TODO: make sure thread safe to do require here
        unless facter_res = Facter.to_hash["sshrsakey"]
          raise Error.new("no ssh public key set")
        end
        dtk_instance_public_key = (facter_res =~ /^ssh-rsa/ ? facter_res : "ssh-rsa #{facter_res}")
      end

      def dtk_instance_username()
        return @dtk_instance_username if @dtk_instance_username
        require 'facter' #TODO: make sure thread safe to do require here
        unless mac = Facter.to_hash["macaddress"]
          raise Error.new("cant find mac address2") 
        end
        @dtk_instance_username = "dtk-#{mac.gsub(/:/,'-')}"
      end
    end
  end
end

