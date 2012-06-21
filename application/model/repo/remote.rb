r8_require("#{::R8::Config[:sys_root_path]}/repo_manager_client/lib/repo_manager_client")
module DTK
  module RepoRemoteClassMixin
    def list_remote(repo_mh)
      repos = client.list_repos()
      repos.map{|r|{:display_name => r}}
    end
   private
    def client()
      RepoManagerClient.new(::R8::Config[:repo][:remote][:rest_base_url])
    end

    def self.public_key_for_repo()
      return @public_key_for_repo if @public_key_for_repo
      require 'facter'
      unless facter_res = Facter.to_hash["sshrsakey"]
        raise Error.new("no ssh public key set")
      end
      @public_key_for_repo = (facter_res =~ /^ssh-rsa/ ? facter_res : "ssh-rsa #{facter_res}")
    end

    def self.id_for_repo()
      return @id_for_repo if @id_for_repo
      require 'facter'
      unless mac = Facter.to_hash["macaddress"]
        raise Error.new("cant find mac address2") 
      end
      @id_for_repo = "dtk-#{mac.gsub(/:/,'-')}"
    end
  end
end
