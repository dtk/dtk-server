r8_require('gitolite_adapter') #TODO: since just one adapter now not dynamically loading in
module DTK::RepoManager
  class Admin
    class << self
      def adapter_class()
        GitoliteAdapter::Admin
      end
      #'pass' all these methods to @repo
      AdminMethods = [:get_repos,:create_repo,:add_user_to_repo,:delete_repo,:add_user,:delete_user]
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
    end
  end
end
