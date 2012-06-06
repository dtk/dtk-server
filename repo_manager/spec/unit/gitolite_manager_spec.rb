#!/usr/bin/env rspec
require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe GitoliteManager do
  repo_name = "test_spec_repo"
  repo_user_acls = 
    [
     {:access_rights => "RW+", :repo_username => "@all"}
    ]
=begin
  before(:all) do
    #TODO: these might be pulled from Config
    @git_user = "git"
  end
=end  
  describe "when creating a repo" do
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
=begin
  describe "while a repo is created" do
    before(:all){GitoliteManager.create_repo(repo_name,repo_user_acls)}
    after(:all){GitoliteManager.delete_repo(repo_name)}
    it "should cause a repo directory to be created in the bare repo" do
      File.directory?("/home/#{@git_user}/repositories/#{repo_name}.git").should == true
    end
  end
=end
end
