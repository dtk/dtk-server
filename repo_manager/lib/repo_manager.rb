#TODO: refering to common r8server apps, which will be made to a common gem
require File.expand_path('../../application/require_first', File.dirname(__FILE__))
require File.expand_path('../../utils/internal/errors/rest_error', File.dirname(__FILE__))
require File.expand_path('../../utils/internal/log', File.dirname(__FILE__))
module R8
  module RepoManager
  end
end

%w{config git_repo gitolite_manager}.each do |f|
  r8_nested_require('repo_manager',f)
end

module R8::RepoManager
  class Error < NameError
  end
  module Log
    def self.info(msg, out = $stdout)
      ::XYZ::Log.info(msg, out)
    end
    def self.debug(msg, out = $stdout)
      ::XYZ::Log.debug(msg, out)
    end
    def self.error(msg, out = $stdout)
      ::XYZ::Log.error(msg, out)
    end
  end
end


