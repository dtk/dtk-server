#TODO: refering to common r8server apps, which will be made to a common gem
#TODO: replace local copies of GritAdapter with common version
require File.expand_path('../../application/require_first', File.dirname(__FILE__))
require File.expand_path('../../utils/internal/errors/rest_error', File.dirname(__FILE__))
require File.expand_path('../../utils/internal/log', File.dirname(__FILE__))
module DTK
  module RepoManager
    def self.bare_repo_dir(repo_name)
      "#{Config[:git_user_home]}/repositories/#{repo_name}.git"
    end
  end
end

%w{config repo admin}.each do |f|
  r8_nested_require('repo_manager',f)
end

module DTK::RepoManager
  class Error < NameError
  end
  module Log
    def self.info(msg)
      ::Ramaze::Log.info(msg)
    end
    def self.debug(msg)
      ::Ramaze::Log.debug(msg)
    end
    def self.error(msg)
      ::Ramaze::Log.error(msg)
    end
  end
end


