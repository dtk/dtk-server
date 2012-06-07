#!/usr/bin/env rspec
require File.expand_path('../../spec_helper', File.dirname(__FILE__))

describe GitoliteManager::Repo do
  before(:all) do
    @test_repo_name = "test_spec_repo"
    @repo_user_acls = 
      [
       {:access_rights => "RW+", :repo_username => "@all"}
      ]
    #TODO: these might be pulled from Config
    @git_user = "git"
  end
  describe "while a repo is created" do
    before(:all) do 
      GitoliteManager::Admin.create_repo(@test_repo_name,@repo_user_acls)
      @test_file_content = "test content\n"
      @test_file_name = "test_file"
      @test_repo = GitoliteManager::Repo.new(@test_repo_name)
    end
    after(:all) do 
#      GitoliteManager::Admin.delete_repo(@test_repo_name)
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
