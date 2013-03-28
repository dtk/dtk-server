require 'rubygems'
require 'rest_client'
require 'pp'
require 'json'
require 'awesome_print'

STDOUT.sync = true

shared_context "Import remote module" do |module_name|
  it "imports module from remote repo" do
    pass = false
    value = `dtk module import #{module_name}`
    pass = value.include? "module_directory:"
    pass.should eq(true)
  end
end

shared_context "Import versioned module from remote" do |dtk_common, module_name, version|
  it "checks existance of module and imports versioned module from remote repo" do
    module_imported = dtk_common.import_versioned_module_from_remote(module_name, version)
    module_imported.should eq(true)
  end
end

shared_context "Get module components list" do |dtk_common, module_name|
  it "gets list of all components modules" do
    $module_components_list = dtk_common.get_module_components_list(module_name, "")
    empty_list = $module_components_list.empty?
    empty_list.should eq(false)
  end
end

shared_context "Get versioned module components list" do |dtk_common, module_name, version|
  it "gets list of components modules from version #{version}" do
    $versioned_module_components_list = dtk_common.get_module_components_list(module_name, version)
    empty_list = $versioned_module_components_list.empty?
    empty_list.should eq(false)
  end
end

shared_context "Check module imported on local filesystem" do |module_filesystem_location, module_name|
  it "checks if module imported on local filesystem" do
    pass = false
    value = `ls #{module_filesystem_location}/#{module_name}`
    pass = !value.include?("No such file or directory")
    pass.should eq(true)
  end
end

shared_context "Check versioned module imported on local filesystem" do |module_filesystem_location, module_name, module_version|
  it "checks if versioned module imported on local filesystem" do
    pass = false
    value = `ls #{module_filesystem_location}/#{module_name}-#{module_version}`
    pass = !value.include?("No such file or directory")
    pass.should eq(true)
  end
end

shared_context "Check if component exists in module" do |dtk_common, module_name, component_name|
  it "check that module contains component" do
    component_exists = dtk_common.check_if_component_exists_in_module(module_name, "", component_name)
    component_exists.should eq(true)
  end
end

shared_context "NEG - Check if component exists in module" do |dtk_common, module_name, component_name|
  it "check that module does not contain component anymore" do
    component_exists = dtk_common.check_if_component_exists_in_module(module_name, "", component_name)
    component_exists.should eq(false)
  end
end

shared_context "Delete module" do |dtk_common, module_name|
  it "deletes module from server" do
    module_deleted = dtk_common.delete_module(module_name)
    module_deleted.should eq(true)
  end
end

shared_context "Delete module from local filesystem" do |module_filesystem_location, module_name|
  it "deletes module from local filesystem" do
    pass = false
    value = `rm -rf #{module_filesystem_location}/#{module_name}`
    pass = !value.include?("cannot remove")
    pass.should eq(true)
  end
end

shared_context "Delete versioned module from local filesystem" do |module_filesystem_location, module_name, module_version|
  it "deletes versioned module from local filesystem" do
    pass = false
    value = `rm -rf #{module_filesystem_location}/#{module_name}-#{module_version}`
    pass = !value.include?("cannot remove")
    pass.should eq(true)
  end
end

shared_context "Create new module version" do |dtk_common, module_name, version|
  it "creates new module version on server" do
    module_versioned = dtk_common.create_new_module_version(module_name, version)
    module_versioned.should eq(true)
  end
end

shared_context "Clone versioned module" do |dtk_common, module_name, module_version|
  it "clones versioned module from server to local filesystem" do
    pass = false
    value = `dtk module #{module_name} clone -v #{module_version} -n`
    pass = value.include?("module_directory:")
    pass.should eq(true)
  end
end

shared_context "Push clone changes to server" do |module_name, file_for_change|
  it "pushes module changes from local filesystem to server" do
    pass = false
    value = `dtk module #{module_name} push-clone-changes`
    pass = value.include?("#{file_for_change}")
    pass.should eq(true)  
  end
end

shared_context "Replace dtk.model.json file with new one" do |module_name, file_for_change_location, file_for_change, module_filesystem_location, it_message|
  it "#{it_message}" do
    pass = false
      `mv #{file_for_change_location} #{module_filesystem_location}/#{module_name}/#{file_for_change}`
    value = `ls #{module_filesystem_location}/#{module_name}/#{file_for_change}`
    pass = !value.include?("No such file or directory")
    pass.should eq(true)
  end
end