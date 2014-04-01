module DTK; class ModuleBranch
  class Location
    #  remote_params = {
    #    :remote_repo_base
    #    :namespace
    #    :module_name
    #    :version 
    #    :rsa_pub_key
    #  }
    class RemoteParams < Params
      def remote_repo_base()
        self[:remote_repo_base]
      end
      def rsa_pub_key()
        self[:rsa_pub_key]
      end
     private
      def legal_keys()
        [:module_name,:remote_repo_base,:version?,:namespace?,:rsa_pub_key?]
      end
    end
    class Remote < RemoteParams 
      attr_reader :remote_branch,:remote_ref,:remote_url
    end
  end
end; end

