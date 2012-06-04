#!/usr/bin/env rspec
require File.expand_path('../spec_helper', File.dirname(__FILE__))

describe GitoliteManager do
  describe "when creating a repo" do
    it "should .." do
      repo_name = "test2"
      repo_user_acls = 
        [
         {:access_rights => "RW+", :repo_username => "@all"}
        ]
      GitoliteManager.create_repo(repo_name,repo_user_acls).should == repo_name
    end
  end
end
