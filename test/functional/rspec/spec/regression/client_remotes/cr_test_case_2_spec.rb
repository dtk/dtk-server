#!/usr/bin/env ruby
# Test Case 2: Import from Github, check remotes, make changes and push-remote and make sure changes are pushed

require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/component_modules_spec'

github_ssh_repo_url = "git@github.com:bjusufbe/puppet-wget.git"
github_namespace_1 = "github1"
github_namespace_2 = "github2"
provider_name = "github"
component_module_name = "wget"
default_filesystem_location = "~/dtk/component_modules"
github_1_component_module_filesystem_location = "~/dtk/component_modules/github1"
github_2_component_module_filesystem_location = "~/dtk/component_modules/github2"

dtk_common = DtkCommon.new('', '')

describe "(Client remotes) Test Case 2: Import from Github, check remotes, make changes and push-remote and make sure changes are pushed" do

  before(:all) do
    puts "******************************************************************************************************************************",""
  end

  context "Import component module from git repo (github)" do
    include_context "Import component module from provided git repo", github_namespace_1 + "/" + component_module_name, github_ssh_repo_url
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, github_namespace_1 + ":" + component_module_name
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", github_1_component_module_filesystem_location, component_module_name
  end

  context "Check remotes and verify that expected remote exists" do
    include_context "Check remotes and verify that expected remote exists", dtk_common, github_namespace_1 + ":" + component_module_name, provider_name, github_ssh_repo_url
  end

  context "Create new file in #{github_1_component_module_filesystem_location}/#{component_module_name}" do
    it "creates new file with content in it" do
      puts "Create new file with content in module directory", "---------------------------------------------------"
      pass = false
      `echo "testdata" > #{github_1_component_module_filesystem_location}/#{component_module_name}/testdata`
      value = `ls #{github_1_component_module_filesystem_location}/#{component_module_name}/testdata`
      pass = !value.include?("No such file or directory")
      puts ""
      expect(pass).to eq(true)
    end
  end

  context "Push clone changes of component module from local copy to server" do
    include_context "Push clone changes to server", github_namespace_1 + ":" + component_module_name, "testdata"
  end

  context "Push to remote" do
    include_context "Push to remote", github_namespace_1 + ":" + component_module_name, provider_name
  end

  context "Remove remote" do
    include_context "Remove remote", dtk_common, github_namespace_1 + ":" + component_module_name, provider_name
  end

  context "Import component module from git repo (github)" do
    include_context "Import component module from provided git repo", github_namespace_2 + "/" + component_module_name, github_ssh_repo_url
  end

  context "Get component module components list" do
    include_context "Get component module components list", dtk_common, github_namespace_2 + ":" + component_module_name
  end

  context "Check if component module imported on local filesystem" do
    include_context "Check component module imported on local filesystem", github_2_component_module_filesystem_location, component_module_name
  end

  context "Check content of pushed file in #{github_2_component_module_filesystem_location}/#{component_module_name}" do
    it "checks that correct content exists which means that module has been pushed to remote successfully" do
      puts "Check content of pushed file", "--------------------------------"
      pass = false
      value = `cat #{github_2_component_module_filesystem_location}/#{component_module_name}/testdata`
      pass = value.include?("testdata")
      puts ""
      expect(pass).to eq(true)
    end
  end

  context "Delete file in #{github_2_component_module_filesystem_location}/#{component_module_name}" do
    it "deletes file" do
      puts "Delete file", "--------------"
      pass = false
      `rm #{github_2_component_module_filesystem_location}/#{component_module_name}/testdata`
      value = `ls #{github_2_component_module_filesystem_location}/#{component_module_name}/testdata`
      pass = !value.include?("No such file or directory")
      puts ""
      expect(pass).to eq(true)
    end
  end

  context "Push clone changes of component module from local copy to server" do
    include_context "Push clone changes to server", github_namespace_2 + ":" + component_module_name, "testdata"
  end

  context "Push to remote" do
    include_context "Push to remote", github_namespace_2 + ":" + component_module_name, provider_name
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, github_namespace_1 + ":" + component_module_name
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", github_1_component_module_filesystem_location, component_module_name
  end

  context "Delete component module" do
    include_context "Delete component module", dtk_common, github_namespace_2 + ":" + component_module_name
  end

  context "Delete component module from local filesystem" do
    include_context "Delete component module from local filesystem", github_2_component_module_filesystem_location, component_module_name
  end

  after(:all) do
    puts "", ""
  end
end