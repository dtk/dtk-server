require 'rubygems'
require 'rspec'
require File.expand_path('../lib/repo_manager', File.dirname(__FILE__))
include R8::RepoManager

def temporarily_create_repo(repo_name,&block)
  repo_user_acls =
    [
     {:access_rights => "RW+", :repo_username => "@all"}
    ]

  ret = yield
  GitoliteManager.delete_repo(repo_name)
  ret
end
