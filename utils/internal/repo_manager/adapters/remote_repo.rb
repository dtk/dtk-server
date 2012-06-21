r8_require('git_service')
r8_nested_require('git_service','rest')
module DTK
  class RepoManagerRemoteRepo < RepoManagerGitService
    class RemoteRepo < Rest
      def self.rest_base_url()
        ::R8::Config[:repo][:remote][:rest_base_url]
      end
    end
   private
    def self.adapter_class()
      RemoteRepo
    end
  end
end
