#TODO: refering to common r8server apps, which wil be made to a common gem
require '/root/R8Server/application/require_first.rb'
r8_nested_require('repo_manager','config')
r8_nested_require('repo_manager','git_repo')
r8_nested_require('repo_manager','gitolite_manager')
