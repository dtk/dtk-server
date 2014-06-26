require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

shared_context "Import remote component module" do |component_module_name|
  it "imports #{component_module_name} component module from remote repo" do
    puts "Import remote component module:", "-------------------------------"
    pass = true
    value = `dtk component-module install #{component_module_name}`
    puts value
    pass = false if ((value.include? "ERROR") || (value.include? "exists on client") || (value.include? "denied") || (value.include? "Conflicts with existing server local module")) 
    puts "Import of remote component module #{component_module_name} completed successfully!" if pass == true
    puts "Import of remote component module #{component_module_name} did not complete successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Import component module from provided git repo" do |component_module_name, git_ssh_repo_url|
  it "imports #{component_module_name} component module from #{git_ssh_repo_url} repo" do
    puts "Import component module from git repo:", "--------------------------------------"
    pass = true
    value = `dtk component-module import-git #{git_ssh_repo_url} #{component_module_name}`
    puts value
    pass = false if ((value.include? "ERROR") || (value.include? "Repository not found") || (value.include? "denied"))
    puts "Component module #{component_module_name} created successfully from provided git repo!" if pass == true
    puts "Component module #{component_module_name} was not created successfully from provided git repo!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "NEG - Import component module from provided git repo" do |component_module_name, git_ssh_repo_url|
  it "does not import #{component_module_name} component module from #{git_ssh_repo_url} repo" do
    puts "NEG - Import component module from git repo:", "--------------------------------------------"
    pass = false
    value = `dtk component-module import-git #{git_ssh_repo_url} #{component_module_name}`
    puts value
    pass = true if ((value.include? "ERROR") || (value.include? "Repository not found") || (value.include? "denied"))
    puts "Component module #{component_module_name} was not created successfully from provided incorrect git repo!" if pass == true
    puts "Component module #{component_module_name} was created successfully from provided incorrect git repo!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "NEG - Import component module with dependency from provided git repo" do |component_module_name, git_ssh_repo_url, dependency_component_module|
  it "imports #{component_module_name} component module from #{git_ssh_repo_url} repo but with dependency warning on #{dependency_component_module}" do
    puts "NEG - Import component module with dependency from git repo:", "------------------------------------------------------------"
    pass = false
    value = `dtk component-module import-git #{git_ssh_repo_url} #{component_module_name}`
    puts value
    if (value.include? "There are some missing dependencies: [\"#{dependency_component_module}\"]")
      pass = true
    end
    puts "Component module #{component_module_name} was created successfully from provided git repo but with dependency missing warning!" if pass == true
    puts "Component module #{component_module_name} was not created successfully from provided git repo or was created but without dependency warning!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "NEG - Import component module with version dependency from provided git repo" do |component_module_name, git_ssh_repo_url|
  it "imports #{component_module_name} component module from #{git_ssh_repo_url} repo but with version dependency error" do
    puts "NEG - Import component module with version dependency from git repo:", "--------------------------------------------------------------------"
    pass = false
    value = `dtk component-module import-git #{git_ssh_repo_url} #{component_module_name}`
    puts value
    if (value.include? "There are some inconsistent dependencies")
      pass = true 
    end
    puts "Component module #{component_module_name} was created successfully from provided git repo but with version dependency missing error!" if pass == true
    puts "Component module #{component_module_name} was not created successfully from provided git repo or was created but without dependency error!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Import component module" do |component_module_name|
  it "imports #{component_module_name} component module from content on local machine" do
    puts "Import component module:", "------------------------"
    pass = false
    value = `dtk component-module import #{component_module_name}`
    puts value
    pass = true unless value.include? "ERROR"
    puts "Component module #{component_module_name} imported successfully!" if pass == true
    puts "Component module #{component_module_name} was not imported successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Export component module" do |dtk_common, component_module_name, namespace|
  it "exports #{component_module_name} component module to #{namespace} namespace on remote repo" do
    puts "Export component module:", "------------------------"
    pass = false
    value = `dtk component-module #{component_module_name} publish #{namespace}/#{component_module_name}`
    puts value
    pass = true unless value.include? "ERROR"
    puts "Component module #{component_module_name} exported successfully!" if pass == true
    puts "Component module #{component_module_name} was not exported successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

# shared_context "OLD - Export module" do |dtk_common, component_module_name, namespace|
#  it "exports #{component_module_name} module to #{namespace} namespace on remote repo" do
#    module_exported = dtk_common.export_module_to_remote(component_module_name, namespace)
#    module_exported.should eq(true)
#  end
# end

shared_context "Import versioned component module from remote" do |dtk_common, component_module_name, version|
  it "checks existance of #{component_module_name} component module and imports component module with version #{version} from remote repo" do
    component_module_imported = dtk_common.import_versioned_component_module_from_remote(component_module_name, version)
    component_module_imported.should eq(true)
  end
end

shared_context "Check if component module exists" do |dtk_common, component_module_name|
  it "checks that component module #{component_module_name} exists on server" do
    component_module_exists = dtk_common.check_if_component_module_exists(component_module_name)
    component_module_exists.should eq(true)
  end
end

shared_context "NEG - Check if component module exists" do |dtk_common, component_module_name|
  it "checks that component module #{component_module_name} does not exist on server" do
    component_module_exists = dtk_common.check_if_component_module_exists(component_module_name)
    component_module_exists.should_not eq(true)
  end
end

shared_context "Get component module components list" do |dtk_common, component_module_name|
  it "gets list of all components in #{component_module_name} component module" do
    # delete previous elements in array
    dtk_common.component_module_id_list.delete_if { |x| x != nil }
    dtk_common.get_component_module_components_list(component_module_name, "")
    empty_list = dtk_common.component_module_id_list.empty?
    empty_list.should eq(false)
  end
end

shared_context "NEG - Get component module components list" do |dtk_common, component_module_name|
  it "gets empty list of all components since #{component_module_name} component module does not exist" do
    # delete previous elements in array
    dtk_common.component_module_id_list.delete_if { |x| x != nil }
    dtk_common.get_component_module_components_list(component_module_name, "")
    empty_list = dtk_common.component_module_id_list.empty?
    empty_list.should eq(true)
  end
end

shared_context "Get versioned component module components list" do |dtk_common, component_module_name, version|
  it "gets list of all components for version #{version} of #{component_module_name} component module" do
    # delete previous elements in array
    dtk_common.component_module_id_list.delete_if { |x| x != nil }
    dtk_common.get_component_module_components_list(component_module_name, version)
    empty_list = dtk_common.component_module_id_list.empty?
    empty_list.should eq(false)
  end
end

shared_context "Get component module attributes list" do |dtk_common, component_module_name, filter_component|
  it "gets list of all attributes in #{component_module_name} component module" do
    attributes_list = dtk_common.get_component_module_attributes_list(component_module_name, filter_component)
    empty_list = attributes_list.empty? 
    empty_list.should eq(false)
  end
end

shared_context "Get component module attributes list by component" do |dtk_common, component_module_name, component_name|
  it "gets list of all attributes in #{component_module_name} component module that belong to #{component_name} component" do
    attributes_list = dtk_common.get_component_module_attributes_list_by_component(component_module_name, component_name)
    empty_list = attributes_list.empty? 
    empty_list.should eq(false)
  end
end

shared_context "Check if expected attribute value exists for given attribute name" do |dtk_common, component_module_name, component_name, attribute_name, attribute_value|
  it "gets attribute value for attribute #{attribute_name} from the component module #{component_module_name} and verifies it is equal to #{attribute_value}" do
    attribute = dtk_common.get_attribute_value_from_component_module(component_module_name, component_name, attribute_name)
    expect(attribute).to eq(attribute_value)
  end
end

shared_context "Check component module imported on local filesystem" do |component_module_filesystem_location, component_module_name|
  it "checks that #{component_module_name} component module is imported on local filesystem on location #{component_module_filesystem_location}" do
    puts "Check component module imported on local filesystem:", "----------------------------------------------------"
    pass = false
    `ls #{component_module_filesystem_location}/#{component_module_name}`
    pass = true if $?.exitstatus == 0
    if (pass == true)
      puts "Component module #{component_module_name} imported on local filesystem successfully!" 
    else
      puts "Component module #{component_module_name} was not imported on local filesystem successfully!"
    end
    puts ""
    pass.should eq(true)
  end
end

shared_context "Check versioned module imported on local filesystem" do |component_module_filesystem_location, component_module_name, module_version|
  it "checks that #{component_module_name} component module with version #{module_version} is imported on local filesystem on location #{component_module_filesystem_location}" do
    puts "Check versioned component module imported on local filesystem:", "----------------------------------------------------"
    pass = false
    value = `ls #{component_module_filesystem_location}/#{component_module_name}-#{module_version}`
    pass = !value.include?("No such file or directory")
    puts "Versioned component module #{component_module_name} imported on local filesystem successfully!" if pass == true
    puts "Versioned component module #{component_module_name} was not imported on local filesystem successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Check if component exists in component module" do |dtk_common, component_module_name, component_name|
  it "check that #{component_module_name} component module contains #{component_name} component" do
    component_exists = dtk_common.check_if_component_exists_in_component_module(component_module_name, "", component_name)
    component_exists.should eq(true)
  end
end

shared_context "NEG - Check if component exists in component module" do |dtk_common, component_module_name, component_name|
  it "check that #{component_module_name} component module does not contain #{component_name} component anymore" do
    component_exists = dtk_common.check_if_component_exists_in_component_module(component_module_name, "", component_name)
    component_exists.should eq(false)
  end
end

shared_context "Delete component module" do |dtk_common, component_module_name|
  it "deletes #{component_module_name} component module from server" do
    component_module_deleted = dtk_common.delete_component_module(component_module_name)
    component_module_deleted.should eq(true)
  end
end

shared_context "Delete component module from local filesystem" do |component_module_filesystem_location, component_module_name|
  it "deletes #{component_module_name} component module from local filesystem" do
    puts "Delete component module from local filesystem:", "----------------------------------------------"
    pass = false
    value = `rm -rf #{component_module_filesystem_location}/#{component_module_name}`
    pass = !value.include?("cannot remove")
    puts "Component module #{component_module_name} deleted from local filesystem successfully!" if pass == true
    puts "Component module #{component_module_name} was not deleted from local filesystem successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Delete versioned component module from local filesystem" do |component_module_filesystem_location, component_module_name, component_module_version|
  it "deletes #{component_module_name} component module with version #{component_module_version} from local filesystem" do
    puts "Delete versioned component module from local filesystem:", "--------------------------------------------------------"
    pass = false
    value = `rm -rf #{component_module_filesystem_location}/#{component_module_name}-#{component_module_version}`
    pass = !value.include?("cannot remove")
    puts "Versioned component module #{component_module_name} deleted from local filesystem successfully!" if pass == true
    puts "Versioned component module #{component_module_name} was not deleted from local filesystem successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Delete component module from remote repo" do |dtk_common, component_module_name, namespace|
  it "deletes #{component_module_name} component module with #{namespace} namespace from remote repo" do
    puts "Delete component module from remote:", "------------------------------------"
    pass = false
    value = `dtk component-module delete-from-catalog #{namespace}/#{component_module_name} -y`
    pass = !value.include?("error")
    puts "Component module #{component_module_name} deleted from dtkn (remote) successfully!" if pass == true
    puts "Component module #{component_module_name} was not deleted from dtkn (remote) successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

# shared_context "OLD - Delete module from remote repo" do |dtk_common, component_module_name, namespace|
#  it "deletes #{component_module_name} module with #{namespace} namespace from remote repo" do
#    module_deleted = dtk_common.delete_module_from_remote(component_module_name, namespace)
#    module_deleted.should eq(true)
#  end
# end

shared_context "Create new component module version" do |dtk_common, component_module_name, version|
  it "creates new version #{version} for #{component_module_name} component module on server" do
    component_module_versioned = dtk_common.create_new_module_version(component_module_name, version)
    component_module_versioned.should eq(true)
  end
end

shared_context "Clone versioned component module" do |dtk_common, component_module_name, module_version|
  it "clones #{component_module_name} component module with version #{module_version} from server to local filesystem" do
    puts "Clone versioned component module:", "---------------------------------"
    pass = false
    value = `dtk component-module #{component_module_name} clone -v #{module_version} -n`
    puts value
    pass = value.include?("module_directory:")
    puts "Versioned component module #{component_module_name} cloned successfully!" if pass == true
    puts "Versioned component module #{component_module_name} was not cloned successfully!" if pass == false
    puts ""
    pass.should eq(true)
  end
end

shared_context "Push clone changes to server" do |component_module_name, file_for_change|
  it "pushes #{component_module_name} component module changes from local filesystem to server with changes on file #{file_for_change}" do
    puts "Push clone changes to server:", "-----------------------------"
    pass = false
    value = `dtk component-module #{component_module_name} push`
    puts value
    pass = value.include?("Status: OK")
    puts "Clone changes pushed to server successfully!" if pass == true
    puts "Clone changes were not pushed to server successfully!" if pass == false
    puts ""
    pass.should eq(true)  
  end
end

shared_context "NEG - Push clone changes to server" do |component_module_name, fail_message, expected_error_message|
  it "pushes #{component_module_name} component module changes from local filesystem to server but fails - reason: #{fail_message}" do
      puts "NEG - Push clone changes to server:", "-----------------------------------"
      fail = false
      value = `dtk component-module #{component_module_name} push`
      puts value
      fail = value.include?(expected_error_message)
      puts ""
      fail.should eq(true)  
    end
end

shared_context "Replace dtk.model.yaml file with new one" do |component_module_name, file_for_change_location, file_for_change, component_module_filesystem_location, it_message|
  it "#{it_message}" do
    puts "Replace dtk.model.yaml file with new one", "----------------------------------------"
    pass = false
    current_path = `pwd`
      `cd #{component_module_filesystem_location}/#{component_module_name};git pull;cd #{current_path}`
      `cp #{file_for_change_location} #{component_module_filesystem_location}/#{component_module_name}/#{file_for_change}`
    value = `ls #{component_module_filesystem_location}/#{component_module_name}/#{file_for_change}`
    pass = !value.include?("No such file or directory")
    puts "Old dtk.model.yaml replaced with new one!" if pass == true
    puts "Old dtk.model.yaml was not replaced with new one!" if pass == false
    puts ""
    pass.should eq(true)
  end
end