r8_require('gitolite_adapter')
module R8::RepoManager
  class Admin
    class << self
      def adapter_class()
        GitoliteAdapter::Admin
      end
      #'pass' all these methods to @repo
      AdminMethods = [:create_repo,:create_repo_and_user,:delete_repo,:add_user,:delete_user]
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
