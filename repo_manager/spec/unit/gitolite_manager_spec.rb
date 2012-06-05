#!/usr/bin/env rspec
require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe GitoliteManager do
  describe "when creating a repo" do
    repo_name = "test_spec_repo"
    repo_user_acls = 
      [
       {:access_rights => "RW+", :repo_username => "@all"}
      ]
    it "should create a new repo first time" do
      GitoliteManager.create_repo(repo_name,repo_user_acls).should == repo_name
    end
    it "should raise an error when trying to create repo that exists" do
      proc{GitoliteManager.create_repo(repo_name,repo_user_acls)}.should raise_error
    end
    it "should succeed when deleting an existing repo" do
      GitoliteManager.delete_repo(repo_name).should == repo_name
    end
  end
end
