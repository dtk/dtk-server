#TODO: refering to common r8server apps, which wil be made to a common gem
require File.expand_path('../../R8Server/application/require_first', File.dirname(__FILE__))
module R8
end
%w{config git_bare_repo gitolite_manager}.each do |f|
  r8_nested_require('repo_manager',f)
end
