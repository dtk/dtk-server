#!/usr/bin/env ruby
# Test Case 28: Import new module from git (does not have dependencies) and check ModuleFile metadata

require 'rubygems'
require 'active_record'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'
require './lib/dtk_common'
require './lib/services_spec'
require './lib/modules_spec'

module_name = "firewall"
git_ssh_repo_url = "git@github.com:puppetlabs/puppetlabs-firewall.git"
module_filesystem_location = "~/dtk/component_modules"
$assembly_id = 0
$metadata = ""
dtk_common = Common.new('', '')

def get_metadata(module_name)
	db_config = YAML::load(File.open('./config/config.yml'))
	ActiveRecord::Base.establish_connection(db_config["dtkserverdbconnection"])
	sql1 = "select id from module.component where ref = '#{module_name}'"
	module_id = ActiveRecord::Base.connection.execute(sql1)
	sql2 = "select external_ref from module.branch where component_id = #{module_id.first['id']}"
	module_metadata = ActiveRecord::Base.connection.execute(sql2)
	return module_metadata.first['external_ref']
end

describe "(Modules, Services and Versioning) Test Case 28: Import new module from git (does not have dependencies) and check ModuleFile metadata" do

  before(:all) do
    puts "**************************************************************************************************************************************"
    puts "(Modules, Services and Versioning) Test Case 28: Import new module from git (does not have dependencies) and check ModuleFile metadata"
    puts "**************************************************************************************************************************************"
    puts ""
  end

  context "Import module from git repo" do
    include_context "Create module from provided git repo", module_name, git_ssh_repo_url
  end

  context "Check if module imported on local filesystem" do
    include_context "Check module imported on local filesystem", module_filesystem_location, module_name
  end

  context "ModuleFile metadata - get content from database" do
    it "gets metadata content from database" do
      $metadata = get_metadata(module_name)
      expect($metadata).not_to be_nil
    end
  end

  context "ModuleFile metadata - name with value puppetlabs-firewall" do
  	it "is correctly parsed and saved into the tenant database" do
  		expect($metadata).to include(":name=>\"puppetlabs-firewall\"")
  	end
  end

  context "ModuleFile metadata - version with value 0.4.2" do
  	it "is correctly parsed and saved into the tenant database" do
  		expect($metadata).to include(":version=>\"0.4.2\"")
  	end
  end

  context "ModuleFile metadata - source with value git://github.com/puppetlabs/puppetlabs-firewall.git" do
  	it "is correctly parsed and saved into the tenant database" do
  		expect($metadata).to include(":source=>\"git://github.com/puppetlabs/puppetlabs-firewall.git\"")
  	end
  end

  context "ModuleFile metadata - author with value puppetlabs" do
  	it "is correctly parsed and saved into the tenant database" do
  		expect($metadata).to include(":author=>\"puppetlabs\"")
  	end
  end

  context "ModuleFile metadata - summary" do
  	it "is correctly parsed and saved into the tenant database" do
  		expect($metadata).to include(":summary")
  	end
  end

  context "ModuleFile metadata - description" do
  	it "is correctly parsed and saved into the tenant database" do
  		expect($metadata).to include(":description")
  	end
  end

  context "ModuleFile metadata - project_page with value http://forge.puppetlabs.com/puppetlabs/firewall" do
  	it "is correctly parsed and saved into the tenant database" do
  		expect($metadata).to include(":project_page=>\"http://forge.puppetlabs.com/puppetlabs/firewall\"")
  	end
  end

  context "Delete module" do
    include_context "Delete module", dtk_common, module_name
  end

  context "Delete module from local filesystem" do
    include_context "Delete module from local filesystem", module_filesystem_location, module_name
  end

  after(:all) do
    puts "", ""
  end
end