#!/usr/bin/env rspec
require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe Admin do
  before(:all) do
    @test_repo_name = "test_spec_repo"
    @repo_user_acls = 
      [
       {:access_rights => "RW+", :repo_username => "@all"}
      ]
    #TODO: this might be pulled from Config
    @git_user = "git"
  end

  describe "when creating a repo" do
    it "should create a new repo first time" do
      Admin.create_repo(@test_repo_name,@repo_user_acls).should == @test_repo_name
    end
    it "should raise an error when trying to create repo that exists" do
      proc{Admin.create_repo(@test_repo_name,@repo_user_acls)}.should raise_error
    end
    it "should cause a repo directory to be created in the bare repo" do
      File.directory?("/home/#{@git_user}/repositories/#{@test_repo_name}.git").should == true
    end
    it "should succeed when deleting an existing repo" do
      Admin.delete_repo(@test_repo_name).should == @test_repo_name
    end
  end
end
