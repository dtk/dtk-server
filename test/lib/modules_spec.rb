require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

STDOUT.sync = true

shared_context "Import remote module" do |module_name|
  it "imports #{module_name} module from remote repo" do
    puts "Import remote module:", "---------------------"
    pass = false
    value = `dtk module import-r8n #{module_name}`
    pass = true if ((!value.include? "[ERROR]") || (!value.include? "exists on client"))
    puts "Import of remote module #{module_name} completed successfully!" if pass == true
    puts "Import of remote module #{module_name} did not complete successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Import module from puppet forge" do |puppet_forge_module_name|
  it "imports #{puppet_forge_module_name} module from puppet forge" do
    puts "Import module from puppet forge:", "---------------------"
    pass = false
    value = `dtk module import-puppet-forge #{puppet_forge_module_name}`
    pass = true if ((!value.include? "[ERROR]") || (!value.include? "Puppet module '#{puppet_forge_module_name}' not found."))
    puts "Import of puppet forge module #{puppet_forge_module_name} completed successfully!" if pass == true
    puts "Import of puppet forge module #{puppet_forge_module_name} did not complete successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "NEG - Import module from puppet forge" do |puppet_forge_module_name|
  it "does not import #{puppet_forge_module_name} module from puppet forge" do
    puts "NEG - Import module from puppet forge:", "---------------------"
    pass = false
    value = `dtk module import-puppet-forge #{puppet_forge_module_name}`
    pass = true if ((value.include? "[ERROR]") || (value.include? "Puppet module '#{puppet_forge_module_name}' not found."))
    puts "Import of incorrect puppet forge module #{puppet_forge_module_name} was not completed successfully!" if pass == true
    puts "Import of incorrect puppet forge module #{puppet_forge_module_name} was completed successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Create module from provided git repo" do |module_name, git_ssh_repo_url|
  it "creates #{module_name} module from #{git_ssh_repo_url} repo" do
    puts "Create module from git repo:", "---------------------"
    pass = false
    value = `dtk module import-git #{module_name} #{git_ssh_repo_url}`
    pass = true if ((!value.include? "[ERROR]") || (!value.include? "Git repository URL '#{git_ssh_repo_url}' is invalid."))
    puts "Module #{module_name} created successfully from provided git repo!" if pass == true
    puts "Module #{module_name} was not created successfully from provided git repo!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "NEG - Create module from provided git repo" do |module_name, git_ssh_repo_url|
  it "does not create #{module_name} module from #{git_ssh_repo_url} repo" do
    puts "NEG - Create module from git repo:", "---------------------"
    pass = false
    value = `dtk module import-git #{module_name} #{git_ssh_repo_url}`
    pass = true if ((value.include? "[ERROR]") || (value.include? "Git repository URL '#{git_ssh_repo_url}' is invalid."))
    puts "Module #{module_name} was not created successfully from provided incorrect git repo!" if pass == true
    puts "Module #{module_name} was created successfully from provided incorrect git repo!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Create module" do |module_name|
  it "creates #{module_name} module from content on local machine" do
    puts "Create module:", "--------------"
    pass = false
    value = `dtk module import #{module_name}`
    pass = value.include? "module_created: #{module_name}"
    puts "Module #{module_name} created successfully!" if pass == true
    puts "Module #{module_name} was not created successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Export module" do |dtk_common, module_name, namespace|
  it "exports #{module_name} module to #{namespace} namespace on remote repo" do
    module_exported = dtk_common.export_module_to_remote(module_name, namespace)
    module_exported.should eq(true)
  end
end

shared_context "Import versioned module from remote" do |dtk_common, module_name, version|
  it "checks existance of #{module_name} module and imports module with version #{version} from remote repo" do
    module_imported = dtk_common.import_versioned_module_from_remote(module_name, version)
    module_imported.should eq(true)
  end
end

shared_context "Get module components list" do |dtk_common, module_name|
  it "gets list of all components in #{module_name} module" do
    #delete previous elements in array
    dtk_common.component_module_id_list.delete_if { |x| x != nil }
    dtk_common.get_module_components_list(module_name, "")
    empty_list = dtk_common.component_module_id_list.empty?
    empty_list.should eq(false)
  end
end

shared_context "NEG - Get module components list" do |dtk_common, module_name|
  it "gets empty list of all components since #{module_name} module does not exist" do
    #delete previous elements in array
    dtk_common.component_module_id_list.delete_if { |x| x != nil }
    dtk_common.get_module_components_list(module_name, "")
    empty_list = dtk_common.component_module_id_list.empty?
    empty_list.should eq(true)
  end
end

shared_context "Get versioned module components list" do |dtk_common, module_name, version|
  it "gets list of all components for version #{version} of #{module_name} module" do
    #delete previous elements in array
    dtk_common.component_module_id_list.delete_if { |x| x != nil }
    dtk_common.get_module_components_list(module_name, version)
    empty_list = dtk_common.component_module_id_list.empty?
    empty_list.should eq(false)
  end
end

shared_context "Check module imported on local filesystem" do |module_filesystem_location, module_name|
  it "checks that #{module_name} module is imported on local filesystem on location #{module_filesystem_location}" do
    puts "Check module imported on local filesystem:", "------------------------------------------"
    pass = false
    `ls #{module_filesystem_location}/#{module_name}`
    pass = true if $?.exitstatus == 0
    if (pass == true)
      puts "Module #{module_name} imported on local filesystem successfully!" 
    else
      puts "Module #{module_name} was not imported on local filesystem successfully!"
    end
    puts ""
    pass.should eq(true)
  end
end

shared_context "Check versioned module imported on local filesystem" do |module_filesystem_location, module_name, module_version|
  it "checks that #{module_name} module with version #{module_version} is imported on local filesystem on location #{module_filesystem_location}" do
    puts "Check versioned module imported on local filesystem:", "----------------------------------------------------"
    pass = false
    value = `ls #{module_filesystem_location}/#{module_name}-#{module_version}`
    pass = !value.include?("No such file or directory")
    puts "Versioned module #{module_name} imported on local filesystem successfully!" if pass == true
    puts "Versioned module #{module_name} was not imported on local filesystem successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Check if component exists in module" do |dtk_common, module_name, component_name|
  it "check that #{module_name} module contains #{component_name} component" do
    component_exists = dtk_common.check_if_component_exists_in_module(module_name, "", component_name)
    component_exists.should eq(true)
  end
end

shared_context "NEG - Check if component exists in module" do |dtk_common, module_name, component_name|
  it "check that #{module_name} module does not contain #{component_name} component anymore" do
    component_exists = dtk_common.check_if_component_exists_in_module(module_name, "", component_name)
    component_exists.should eq(false)
  end
end

shared_context "Delete module" do |dtk_common, module_name|
  it "deletes #{module_name} module from server" do
    module_deleted = dtk_common.delete_module(module_name)
    module_deleted.should eq(true)
  end
end

shared_context "Delete module from local filesystem" do |module_filesystem_location, module_name|
  it "deletes #{module_name} module from local filesystem" do
    puts "Delete module from local filesystem:", "------------------------------------"
    pass = false
    value = `rm -rf #{module_filesystem_location}/#{module_name}`
    pass = !value.include?("cannot remove")
    puts "Module #{module_name} deleted from local filesystem successfully!" if pass == true
    puts "Module #{module_name} was not deleted from local filesystem successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Delete versioned module from local filesystem" do |module_filesystem_location, module_name, module_version|
  it "deletes #{module_name} module with version #{module_version} from local filesystem" do
    puts "Delete versioned module from local filesystem:", "----------------------------------------------"
    pass = false
    value = `rm -rf #{module_filesystem_location}/#{module_name}-#{module_version}`
    pass = !value.include?("cannot remove")
    puts "Versioned module #{module_name} deleted from local filesystem successfully!" if pass == true
    puts "Versioned module #{module_name} was not deleted from local filesystem successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Delete module from remote repo" do |dtk_common, module_name, namespace|
  it "deletes #{module_name} module with #{namespace} namespace from remote repo" do
    module_deleted = dtk_common.delete_module_from_remote(module_name, namespace)
    module_deleted.should eq(true)
  end
end

shared_context "Create new module version" do |dtk_common, module_name, version|
  it "creates new version #{version} for #{module_name} module on server" do
    module_versioned = dtk_common.create_new_module_version(module_name, version)
    module_versioned.should eq(true)
  end
end

shared_context "Clone versioned module" do |dtk_common, module_name, module_version|
  it "clones #{module_name} module with version #{module_version} from server to local filesystem" do
    puts "Clone versioned module:", "-----------------------"
    pass = false
    value = `dtk module #{module_name} clone -v #{module_version} -n`
    pass = value.include?("module_directory:")
    puts "Versioned module #{module_name} cloned successfully!" if pass == true
    puts "Versioned module #{module_name} was not cloned successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Push clone changes to server" do |module_name, file_for_change|
  it "pushes #{module_name} module changes from local filesystem to server with changes on file #{file_for_change}" do
    puts "Push clone changes to server:", "-----------------------------"
    pass = false
    value = `dtk module #{module_name} push-clone-changes`
    pass = value.include?("#{file_for_change}")
    puts "Clone changes pushed to server successfully!" if pass == true
    puts "Clone changes were not pushed to server successfully!" if pass == false
    puts ""
    pass.should eq(true)  
  end
end

shared_context "Replace dtk.model.json file with new one" do |module_name, file_for_change_location, file_for_change, module_filesystem_location, it_message|
  it "#{it_message}" do
    puts "Replace dtk.model.json file with new one", "----------------------------------------"
    pass = false
    current_path = `pwd`
      `cd #{module_filesystem_location}/#{module_name};git pull;cd #{current_path}`
      `cp #{file_for_change_location} #{module_filesystem_location}/#{module_name}/#{file_for_change}`
    value = `ls #{module_filesystem_location}/#{module_name}/#{file_for_change}`
    pass = !value.include?("No such file or directory")
    puts "Old dtk.model.json replaced with new one!" if pass == true
    puts "Old dtk.model.json was not replaced with new one!" if pass == false
    puts ""
    pass.should eq(true)
  end
end