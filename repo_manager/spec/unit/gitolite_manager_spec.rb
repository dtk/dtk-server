#!/usr/bin/env rspec
require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe GitoliteManager do
  before(:all) do
    @test_repo_name = "test_spec_repo"
    @repo_user_acls = 
      [
       {:access_rights => "RW+", :repo_username => "@all"}
      ]
    #TODO: these might be pulled from Config
    @git_user = "git"
  end

  describe "when creating a repo" do
    it "should create a new repo first time" do
      GitoliteManager::Admin.create_repo(@test_repo_name,@repo_user_acls).should == @test_repo_name
    end
    it "should raise an error when trying to create repo that exists" do
      proc{GitoliteManager::Admin.create_repo(@test_repo_name,@repo_user_acls)}.should raise_error
    end
    it "should succeed when deleting an existing repo" do
      GitoliteManager::Admin.delete_repo(@test_repo_name).should == @test_repo_name
    end
  end

  describe "while a repo is created" do
    before(:all) do 
      GitoliteManager::Admin.create_repo(@test_repo_name,@repo_user_acls)
      @test_file_content = "test content\n"
      @test_file_name = "test_file"
      @test_repo = GitoliteManager::Repo.new(@test_repo_name)
    end
    after(:all) do 
      GitoliteManager::Admin.delete_repo(@test_repo_name)
    end
    it "should cause a repo directory to be created in the bare repo" do
      File.directory?("/home/#{@git_user}/repositories/#{@test_repo_name}.git").should == true
    end
    it "should enable successful creation of a repo instance object" do
      @test_repo.kind_of?(GitoliteManager::Repo).should be_true
    end

    it "should support adding a file and retrieving back the file contents" do
      @test_repo.add_file_and_commit(@test_file_name,@test_file_content)
      @test_repo.file_content(@test_file_name).should == @test_file_content
    end
  end
end
