r8_require('gitolite_adapter') #TODO: since just one adapter now not dynamically loading in
module DTK; module RepoManager
  class Admin
    class << self
      def adapter_class()
        GitoliteAdapter::Admin
      end
      #'pass' all these methods to @repo
      AdminMethods = [:list_repos,:create_repo,:set_user_rights_in_repo,:delete_repo,:add_user,:delete_user,:ret_repo_user_acls]
      def method_missing(name,*args,&block)
        if AdminMethods.include?(name)
          adapter_class().send(name,*args,&block)
        else
          super
        end
      end
      def respond_to?(name)
        !!(AdminMethods.include?(name) || super)
      end

      def dtk_username()
        Common::Aux.dtk_instance_repo_username()
      end

      def get_ssh_rsa_pub_key()
        Common::Aux.get_ssh_rsa_pub_key()
      end
    end
  end
end; end
