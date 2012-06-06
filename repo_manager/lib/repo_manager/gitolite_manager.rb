require 'erubis'
module R8::RepoManager
  module GitoliteManager
    Config = ::R8::RepoManager::Config
  end
end
r8_nested_require('gitolite_manager','admin')
r8_nested_require('gitolite_manager','repo')
